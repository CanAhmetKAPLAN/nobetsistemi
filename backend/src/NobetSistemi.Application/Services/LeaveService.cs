using NobetSistemi.Application.DTOs.Leave;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Enums;
using NobetSistemi.Domain.Exceptions;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.Application.Services;

public class LeaveService : ILeaveService
{
    private readonly ILeaveRequestRepository _leaveRepository;
    private readonly IUserRepository _userRepository;
    private readonly IGroupMembershipRepository _membershipRepository;
    private readonly IDutyRepository _dutyRepository;
    private readonly INotificationService _notificationService;
    private readonly IFcmNotificationService _fcm;
    private readonly IDutyAssignmentService _assignment;
    private readonly ICurrentGroupContext _currentGroupContext;

    public LeaveService(
        ILeaveRequestRepository leaveRepository,
        IUserRepository userRepository,
        IGroupMembershipRepository membershipRepository,
        IDutyRepository dutyRepository,
        INotificationService notificationService,
        IFcmNotificationService fcm,
        IDutyAssignmentService assignment,
        ICurrentGroupContext currentGroupContext)
    {
        _leaveRepository = leaveRepository;
        _userRepository = userRepository;
        _membershipRepository = membershipRepository;
        _dutyRepository = dutyRepository;
        _notificationService = notificationService;
        _fcm = fcm;
        _assignment = assignment;
        _currentGroupContext = currentGroupContext;
    }

    public async Task<IEnumerable<LeaveRequestDto>> GetAllAsync()
    {
        _currentGroupContext.RequireGroupId();
        _currentGroupContext.RequireAdmin();
        var leaves = await _leaveRepository.GetAllAsync();
        return leaves.Select(MapToDto);
    }

    public async Task<LeaveRequestDto> GetByIdAsync(Guid id)
    {
        _currentGroupContext.RequireGroupId();
        var leave = await _leaveRepository.GetByIdAsync(id)
            ?? throw new NotFoundException("İzin talebi bulunamadı.");
        return MapToDto(leave);
    }

    public async Task<IEnumerable<LeaveRequestDto>> GetByUserIdAsync(Guid userId)
    {
        _currentGroupContext.RequireGroupId();
        var leaves = await _leaveRepository.GetByUserIdAsync(userId);
        return leaves.Select(MapToDto);
    }

    public async Task<IEnumerable<LeaveRequestDto>> GetPendingAsync()
    {
        _currentGroupContext.RequireGroupId();
        _currentGroupContext.RequireAdmin();
        var leaves = await _leaveRepository.GetPendingAsync();
        return leaves.Select(MapToDto);
    }

    public async Task<LeaveRequestDto> CreateAsync(Guid userId, CreateLeaveRequestDto dto)
    {
        var groupId = _currentGroupContext.RequireGroupId();

        var start = DateTime.SpecifyKind(dto.StartDate.Date, DateTimeKind.Utc);
        var end   = DateTime.SpecifyKind(dto.EndDate.Date,   DateTimeKind.Utc);

        if (start > end)
            throw new AppException("Başlangıç tarihi bitiş tarihinden sonra olamaz.");

        var user = await _userRepository.GetByIdAsync(userId)
            ?? throw new NotFoundException("Kullanıcı bulunamadı.");

        // İzin direkt onaylanır — admin onayı gerekmez
        var leave = new LeaveRequest
        {
            Id = Guid.NewGuid(),
            GroupId = groupId,
            UserId = userId,
            User = user,
            StartDate = start,
            EndDate = end,
            Reason = string.IsNullOrWhiteSpace(dto.Reason) ? null! : dto.Reason.Trim(),
            Status = LeaveStatus.Approved,
            ReviewedById = userId, // kendi kendine otomatik onay
            CreatedAt = DateTime.UtcNow
        };

        await _leaveRepository.AddAsync(leave);
        await _leaveRepository.SaveChangesAsync();

        // Bildirimi anında gönder
        var body = $"İzniniz ({start:dd/MM/yyyy} - {end:dd/MM/yyyy}) otomatik onaylandı.";
        await _notificationService.CreateAsync(userId, "✅ İzin Onaylandı", body);
        await _fcm.SendToUserAsync(userId, "✅ İzin Onaylandı", body, "leave_approved");

        // İzin süresindeki nöbetleri hemen yeniden ata
        await ReassignDutiesDuringLeaveAsync(leave);

        return MapToDto(leave);
    }

    public async Task<LeaveRequestDto> ReviewAsync(Guid id, Guid reviewerId, ReviewLeaveRequestDto dto)
    {
        _currentGroupContext.RequireGroupId();
        _currentGroupContext.RequireAdmin();

        var leave = await _leaveRepository.GetByIdAsync(id)
            ?? throw new NotFoundException("İzin talebi bulunamadı.");

        if (leave.Status != LeaveStatus.Pending)
            throw new AppException("Bu izin talebi zaten değerlendirilmiş.");

        leave.Status = dto.Approve ? LeaveStatus.Approved : LeaveStatus.Rejected;
        leave.ReviewedById = reviewerId;

        _leaveRepository.Update(leave);
        await _leaveRepository.SaveChangesAsync();

        var statusText = dto.Approve ? "onaylandı" : "reddedildi";
        var notifTitle = dto.Approve ? "✅ İzin Onaylandı" : "❌ İzin Reddedildi";
        var notifBody = $"İzin talebiniz ({leave.StartDate:dd/MM/yyyy} - {leave.EndDate:dd/MM/yyyy}) {statusText}.";
        var fcmType = dto.Approve ? "leave_approved" : "leave_rejected";

        await _notificationService.CreateAsync(leave.UserId, notifTitle, notifBody);
        await _fcm.SendToUserAsync(leave.UserId, notifTitle, notifBody, fcmType);

        // İzin onaylandıysa, izin süresindeki gelecek nöbetleri yeniden ata
        if (dto.Approve)
            await ReassignDutiesDuringLeaveAsync(leave);

        return MapToDto(leave);
    }

    public async Task DeleteAsync(Guid id)
    {
        _currentGroupContext.RequireGroupId();
        _currentGroupContext.RequireAdmin();

        var leave = await _leaveRepository.GetByIdAsync(id)
            ?? throw new NotFoundException("İzin talebi bulunamadı.");
        _leaveRepository.Delete(leave);
        await _leaveRepository.SaveChangesAsync();
    }

    private async Task ReassignDutiesDuringLeaveAsync(LeaveRequest leave)
    {
        var today = DateTime.UtcNow.Date;

        // Sadece bugün ve sonrasındaki nöbetleri yeniden ata (geçmiş tutuldu)
        var fromDate = leave.StartDate.Date >= today ? leave.StartDate.Date : today;
        if (fromDate > leave.EndDate.Date) return;

        var duties = await _dutyRepository.GetByDateRangeAsync(fromDate, leave.EndDate.Date);
        var userDuties = duties.Where(d => d.UserId == leave.UserId).ToList();

        foreach (var duty in userDuties)
        {
            try
            {
                var newMembership = await _assignment.SelectMemberForDateAsync(duty.Date);
                double weight = _assignment.GetDayWeight(duty.Date);

                // Eski kullanıcının puanını geri al
                var oldMembership = await _membershipRepository.GetAsync(leave.GroupId, leave.UserId);
                if (oldMembership is not null && oldMembership.Score >= weight)
                {
                    oldMembership.Score = Math.Round(oldMembership.Score - weight, 4);
                    _membershipRepository.Update(oldMembership);
                }

                // Yeni kullanıcının puanını artır
                newMembership.Score += weight;
                _membershipRepository.Update(newMembership);

                // Nöbeti devret
                duty.UserId = newMembership.UserId;
                _dutyRepository.Update(duty);
                await _dutyRepository.SaveChangesAsync();

                // Bildirimleri gönder
                await _notificationService.CreateAsync(leave.UserId,
                    "🔄 Nöbetiniz Devredildi",
                    $"{duty.Date:dd/MM/yyyy} tarihli nöbetiniz {newMembership.User.Name}'e devredildi.");

                await _notificationService.CreateAsync(newMembership.UserId,
                    "📋 Nöbet Devralındı",
                    $"İzin nedeniyle {duty.Date:dd/MM/yyyy} tarihli nöbet size atandı.");

                await _fcm.SendToUserAsync(leave.UserId,
                    "🔄 Nöbetiniz Devredildi",
                    $"{duty.Date:dd/MM/yyyy} nöbetiniz {newMembership.User.Name}'e devredildi.",
                    "duty_reassigned");

                await _fcm.SendToUserAsync(newMembership.UserId,
                    "📋 Nöbet Devralındı",
                    $"{duty.Date:dd/MM/yyyy} tarihli nöbet size atandı.",
                    "duty_assigned");
            }
            catch (AppException)
            {
                // Uygun vekil bulunamadı — nöbet yerinde kalır, admin bilgilendirilir
                await _notificationService.CreateAsync(leave.UserId,
                    "⚠️ Nöbet Devredilemiyor",
                    $"{duty.Date:dd/MM/yyyy} tarihli nöbet için uygun vekil bulunamadı.");
            }
        }
    }

    private static LeaveRequestDto MapToDto(LeaveRequest leave) => new()
    {
        Id = leave.Id,
        UserId = leave.UserId,
        UserName = leave.User?.Name ?? string.Empty,
        StartDate = leave.StartDate,
        EndDate = leave.EndDate,
        Reason = leave.Reason,
        Status = leave.Status.ToString(),
        ReviewedById = leave.ReviewedById,
        CreatedAt = leave.CreatedAt
    };
}
