using NobetSistemi.Application.DTOs.Swap;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Enums;
using NobetSistemi.Domain.Exceptions;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.Application.Services;

public class SwapService : ISwapService
{
    private readonly IDutySwapRequestRepository _swapRepository;
    private readonly IDutyRepository _dutyRepository;
    private readonly IGroupMembershipRepository _membershipRepository;
    private readonly INotificationService _notificationService;
    private readonly IFcmNotificationService _fcm;
    private readonly ICurrentGroupContext _currentGroupContext;

    public SwapService(
        IDutySwapRequestRepository swapRepository,
        IDutyRepository dutyRepository,
        IGroupMembershipRepository membershipRepository,
        INotificationService notificationService,
        IFcmNotificationService fcm,
        ICurrentGroupContext currentGroupContext)
    {
        _swapRepository = swapRepository;
        _dutyRepository = dutyRepository;
        _membershipRepository = membershipRepository;
        _notificationService = notificationService;
        _fcm = fcm;
        _currentGroupContext = currentGroupContext;
    }

    public async Task<IEnumerable<DutySwapRequestDto>> GetAllAsync()
    {
        _currentGroupContext.RequireGroupId();
        _currentGroupContext.RequireAdmin();
        var swaps = await _swapRepository.GetAllAsync();
        return swaps.Select(MapToDto);
    }

    public async Task<DutySwapRequestDto> GetByIdAsync(Guid id)
    {
        _currentGroupContext.RequireGroupId();
        var swap = await _swapRepository.GetByIdAsync(id)
            ?? throw new NotFoundException("Nöbet değişim talebi bulunamadı.");
        return MapToDto(swap);
    }

    public async Task<IEnumerable<DutySwapRequestDto>> GetByRequesterIdAsync(Guid requesterId)
    {
        _currentGroupContext.RequireGroupId();
        var swaps = await _swapRepository.GetByRequesterIdAsync(requesterId);
        return swaps.Select(MapToDto);
    }

    public async Task<IEnumerable<DutySwapRequestDto>> GetIncomingAsync(Guid targetUserId)
    {
        _currentGroupContext.RequireGroupId();
        var swaps = await _swapRepository.GetByTargetUserIdAsync(targetUserId);
        return swaps.Select(MapToDto);
    }

    public async Task<IEnumerable<DutySwapRequestDto>> GetPendingAsync()
    {
        _currentGroupContext.RequireGroupId();
        _currentGroupContext.RequireAdmin();
        var swaps = await _swapRepository.GetPendingAsync();
        return swaps.Select(MapToDto);
    }

    public async Task<DutySwapRequestDto> CreateAsync(Guid requesterId, CreateSwapRequestDto dto)
    {
        var groupId = _currentGroupContext.RequireGroupId();

        var requesterDuty = await _dutyRepository.GetByIdAsync(dto.RequesterDutyId)
            ?? throw new NotFoundException("Talep eden kullanıcının nöbeti bulunamadı.");

        if (requesterDuty.UserId != requesterId)
            throw new UnauthorizedException("Bu nöbet size ait değil.");

        var targetMembership = await _membershipRepository.GetAsync(groupId, dto.TargetUserId)
            ?? throw new NotFoundException("Hedef kullanıcı bu grubun üyesi değil.");

        if (!targetMembership.IsActive)
            throw new AppException("Hedef kullanıcı pasif durumda.");

        if (dto.TargetDutyId.HasValue)
        {
            var targetDuty = await _dutyRepository.GetByIdAsync(dto.TargetDutyId.Value)
                ?? throw new NotFoundException("Hedef nöbet bulunamadı.");

            if (targetDuty.UserId != dto.TargetUserId)
                throw new AppException("Hedef nöbet, hedef kullanıcıya ait değil.");
        }

        var swap = new DutySwapRequest
        {
            Id = Guid.NewGuid(),
            GroupId = groupId,
            RequesterId = requesterId,
            TargetUserId = dto.TargetUserId,
            RequesterDutyId = dto.RequesterDutyId,
            TargetDutyId = dto.TargetDutyId,
            Reason = dto.Reason,
            Status = SwapStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        await _swapRepository.AddAsync(swap);
        await _swapRepository.SaveChangesAsync();

        const string swapTitle = "🔄 Nöbet Değişim Talebi";
        var swapBody = $"Size yeni bir nöbet değişim talebi gönderildi. Nöbet tarihi: {requesterDuty.Date:dd/MM/yyyy}";
        await _notificationService.CreateAsync(dto.TargetUserId, swapTitle, swapBody);
        await _fcm.SendToUserAsync(dto.TargetUserId, swapTitle, swapBody, "swap_request");

        return MapToDto(swap);
    }

    public async Task<DutySwapRequestDto> ReviewAsync(Guid id, Guid reviewerId, ReviewSwapRequestDto dto)
    {
        _currentGroupContext.RequireGroupId();

        var swap = await _swapRepository.GetByIdAsync(id)
            ?? throw new NotFoundException("Nöbet değişim talebi bulunamadı.");

        // Değişimi, kendisine teklif edilen hedef kullanıcı ya da bir grup
        // yöneticisi onaylayabilir/reddedebilir — admin onayına gerek yok.
        bool isTarget = swap.TargetUserId == reviewerId;
        bool isAdmin = _currentGroupContext.MembershipRole == GroupRole.Admin;
        if (!isTarget && !isAdmin)
            throw new UnauthorizedException("Bu talebi yalnızca hedef kullanıcı veya grup yöneticisi onaylayabilir.");

        if (swap.Status != SwapStatus.Pending)
            throw new AppException("Bu talep zaten değerlendirilmiş.");

        if (dto.Approve)
        {
            // Nöbetleri değiştir
            var requesterDuty = await _dutyRepository.GetByIdAsync(swap.RequesterDutyId)
                ?? throw new NotFoundException("Talep eden nöbeti bulunamadı.");

            requesterDuty.UserId = swap.TargetUserId;
            _dutyRepository.Update(requesterDuty);

            if (swap.TargetDutyId.HasValue)
            {
                var targetDuty = await _dutyRepository.GetByIdAsync(swap.TargetDutyId.Value)
                    ?? throw new NotFoundException("Hedef nöbet bulunamadı.");
                targetDuty.UserId = swap.RequesterId;
                _dutyRepository.Update(targetDuty);
            }

            swap.Status = SwapStatus.Approved;
        }
        else
        {
            swap.Status = SwapStatus.Rejected;
        }

        _swapRepository.Update(swap);
        await _swapRepository.SaveChangesAsync();

        var statusText = dto.Approve ? "onaylandı" : "reddedildi";
        var reviewTitle = dto.Approve ? "✅ Değişim Onaylandı" : "❌ Değişim Reddedildi";
        var reviewBody = $"Nöbet değişim talebiniz {statusText}.";
        var fcmType = dto.Approve ? "swap_approved" : "swap_rejected";

        await _notificationService.CreateAsync(swap.RequesterId, reviewTitle, reviewBody);
        await _fcm.SendToUserAsync(swap.RequesterId, reviewTitle, reviewBody, fcmType);

        return MapToDto(swap);
    }

    public async Task CancelAsync(Guid id, Guid userId)
    {
        _currentGroupContext.RequireGroupId();

        var swap = await _swapRepository.GetByIdAsync(id)
            ?? throw new NotFoundException("Nöbet değişim talebi bulunamadı.");

        if (swap.RequesterId != userId)
            throw new UnauthorizedException("Bu talebi iptal etme yetkiniz yok.");

        if (swap.Status != SwapStatus.Pending)
            throw new AppException("Sadece bekleyen talepler iptal edilebilir.");

        swap.Status = SwapStatus.Cancelled;
        _swapRepository.Update(swap);
        await _swapRepository.SaveChangesAsync();
    }

    private static DutySwapRequestDto MapToDto(DutySwapRequest swap) => new()
    {
        Id = swap.Id,
        RequesterId = swap.RequesterId,
        RequesterName = swap.Requester?.Name ?? string.Empty,
        TargetUserId = swap.TargetUserId,
        TargetUserName = swap.TargetUser?.Name ?? string.Empty,
        RequesterDutyId = swap.RequesterDutyId,
        RequesterDutyDate = swap.RequesterDuty?.Date ?? default,
        TargetDutyId = swap.TargetDutyId,
        TargetDutyDate = swap.TargetDuty?.Date,
        Reason = swap.Reason,
        Status = swap.Status.ToString(),
        CreatedAt = swap.CreatedAt
    };
}
