using NobetSistemi.Application.DTOs.Duty;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Exceptions;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.Application.Services;

public class DutyService : IDutyService
{
    private readonly IDutyRepository _dutyRepository;
    private readonly IGroupMembershipRepository _membershipRepository;
    private readonly INotificationService _notificationService;
    private readonly IDutyAssignmentService _assignment;
    private readonly ICurrentGroupContext _currentGroupContext;

    public DutyService(
        IDutyRepository dutyRepository,
        IGroupMembershipRepository membershipRepository,
        INotificationService notificationService,
        IDutyAssignmentService assignment,
        ICurrentGroupContext currentGroupContext)
    {
        _dutyRepository = dutyRepository;
        _membershipRepository = membershipRepository;
        _notificationService = notificationService;
        _assignment = assignment;
        _currentGroupContext = currentGroupContext;
    }

    public async Task<IEnumerable<DutyDto>> GetAllAsync()
    {
        _currentGroupContext.RequireGroupId();
        var duties = await _dutyRepository.GetAllAsync();
        return duties.Select(MapToDto);
    }

    public async Task<DutyDto> GetByIdAsync(Guid id)
    {
        _currentGroupContext.RequireGroupId();
        var duty = await _dutyRepository.GetByIdAsync(id)
            ?? throw new NotFoundException("Nöbet bulunamadı.");
        return MapToDto(duty);
    }

    public async Task<IEnumerable<DutyDto>> GetByUserIdAsync(Guid userId)
    {
        _currentGroupContext.RequireGroupId();
        var duties = await _dutyRepository.GetByUserIdAsync(userId);
        return duties.Select(MapToDto);
    }

    public async Task<IEnumerable<DutyDto>> GetByDateAsync(DateTime date)
    {
        _currentGroupContext.RequireGroupId();
        var duties = await _dutyRepository.GetByDateAsync(date.Date);
        return duties.Select(MapToDto);
    }

    public async Task<IEnumerable<DutyDto>> GetByYearMonthAsync(int year, int month)
    {
        _currentGroupContext.RequireGroupId();
        var duties = await _dutyRepository.GetByYearMonthAsync(year, month);
        return duties.Select(MapToDto);
    }

    public async Task<IEnumerable<MonthlyScoreDto>> GetMonthlyScoresAsync()
    {
        _currentGroupContext.RequireGroupId();
        var rows = await _dutyRepository.GetMonthlyScoresAsync();
        return rows.Select(r => new MonthlyScoreDto
        {
            UserId = r.UserId,
            UserName = r.UserName,
            Year = r.Year,
            Month = r.Month,
            Score = r.Count
        });
    }

    public async Task<AutoFillResultDto> AutoFillMonthAsync(int year, int month)
    {
        _currentGroupContext.RequireGroupId();
        _currentGroupContext.RequireAdmin();

        var start = new DateTime(year, month, 1, 0, 0, 0, DateTimeKind.Utc);
        var end   = start.AddMonths(1);

        int assigned = 0, skipped = 0, alreadyFilled = 0;
        var duties = new List<DutyDto>();

        for (var date = start; date < end; date = date.AddDays(1))
        {
            var existing = await _dutyRepository.GetByDateAsync(date);
            if (existing.Any()) { alreadyFilled++; continue; }

            try
            {
                var dto = await AutoAssignInternalAsync(date);
                duties.Add(dto);
                assigned++;
            }
            catch (AppException)
            {
                // Bu gün için uygun kullanıcı yok, geç
                skipped++;
            }
        }

        return new AutoFillResultDto
        {
            AssignedCount    = assigned,
            SkippedCount     = skipped,
            AlreadyFilledCount = alreadyFilled,
            Duties           = duties
        };
    }

    /// <summary>
    /// Belirli bir tarih aralığındaki OTOMATİK atanmış nöbetleri güncel üye
    /// listesi ve puanlarla yeniden değerlendirir — sonradan gruba katılan
    /// biri dahil olsun, izin/manuel değişiklik sonrası açılan puan farkı
    /// kendini düzeltsin diye günlük arka plan servisi tarafından da
    /// çağrılır. SADECE atanan kişi gerçekten değişiyorsa o günü silip
    /// yeniden oluşturur (ve ilgili kişilere bildirim gönderir) — kişi
    /// aynı kalıyorsa satıra dokunmaz, gereksiz "nöbetiniz değişti"
    /// bildirim spam'i olmasın diye. Manuel atanmış nöbetlere ve geçmiş
    /// (bugünden önceki) tarihlere asla dokunulmaz.
    /// </summary>
    public async Task<AutoFillResultDto> RebalanceAsync(RebalanceDutiesDto dto)
    {
        var groupId = _currentGroupContext.RequireGroupId();
        _currentGroupContext.RequireAdmin();

        var today = DateTime.UtcNow.Date;
        var start = DateTime.SpecifyKind(dto.FromDate.Date, DateTimeKind.Utc);
        var end = DateTime.SpecifyKind(dto.ToDate.Date, DateTimeKind.Utc);
        if (start < today) start = today;

        if (end < start)
            throw new AppException("Bitiş tarihi başlangıçtan önce olamaz.");

        var existingDuties = (await _dutyRepository.GetByDateRangeAsync(start, end)).ToList();
        var manualDates = existingDuties.Where(d => !d.IsAutoAssigned).Select(d => d.Date.Date).ToHashSet();
        var autoByDate = existingDuties.Where(d => d.IsAutoAssigned).ToDictionary(d => d.Date.Date);

        // Simülasyonun güncel puanlarla baştan başlayabilmesi için önce tüm
        // otomatik atamaların puan etkisini geri al (satırları henüz silmeden).
        foreach (var duty in autoByDate.Values)
        {
            double weight = _assignment.GetDayWeight(duty.Date);
            var membership = await _membershipRepository.GetAsync(duty.GroupId, duty.UserId);
            if (membership is not null && membership.Score >= weight)
            {
                membership.Score = Math.Round(membership.Score - weight, 4);
                _membershipRepository.Update(membership);
            }
        }
        await _dutyRepository.SaveChangesAsync();

        int assigned = 0, skipped = 0, alreadyFilled = 0, unchanged = 0;
        var duties = new List<DutyDto>();

        for (var date = start; date <= end; date = date.AddDays(1))
        {
            if (manualDates.Contains(date.Date)) { alreadyFilled++; continue; }

            var existing = autoByDate.GetValueOrDefault(date.Date);

            try
            {
                var selected = await _assignment.SelectMemberForDateAsync(date);
                double weight = _assignment.GetDayWeight(date);
                selected.Score += weight;
                _membershipRepository.Update(selected);

                if (existing is not null && existing.UserId == selected.UserId)
                {
                    // Kişi değişmedi — satırı olduğu gibi bırak, sadece puanı geri ekle.
                    await _dutyRepository.SaveChangesAsync();
                    duties.Add(MapToDto(existing));
                    unchanged++;
                    continue;
                }

                if (existing is not null)
                {
                    _dutyRepository.Delete(existing);
                    await _notificationService.CreateAsync(existing.UserId,
                        "ℹ️ Nöbet Güncellendi",
                        $"{date:dd/MM/yyyy} tarihli nöbetiniz, güncel adalet dengesi gözetilerek başka bir üyeye aktarıldı.");
                }

                var newDuty = new Duty
                {
                    Id = Guid.NewGuid(),
                    GroupId = groupId,
                    UserId = selected.UserId,
                    User = selected.User,
                    Date = date,
                    IsAutoAssigned = true,
                    CreatedAt = DateTime.UtcNow
                };
                await _dutyRepository.AddAsync(newDuty);
                await _dutyRepository.SaveChangesAsync();

                await _notificationService.CreateAsync(selected.UserId, "Otomatik Nöbet Atandı",
                    $"{date:dd/MM/yyyy} tarihine otomatik nöbet atandınız. (Puan: +{weight:F2})");

                duties.Add(MapToDto(newDuty));
                assigned++;
            }
            catch (AppException)
            {
                skipped++;
            }
        }

        return new AutoFillResultDto
        {
            AssignedCount = assigned,
            SkippedCount = skipped,
            AlreadyFilledCount = alreadyFilled,
            UnchangedCount = unchanged,
            Duties = duties
        };
    }

    public async Task<DutyDto> CreateManualAsync(CreateDutyDto dto)
    {
        var groupId = _currentGroupContext.RequireGroupId();
        _currentGroupContext.RequireAdmin();

        var membership = await _membershipRepository.GetAsync(groupId, dto.UserId)
            ?? throw new NotFoundException("Kullanıcı bu grubun üyesi değil.");

        if (!membership.IsActive)
            throw new AppException("Pasif kullanıcıya nöbet atanamaz.");

        var date = DateTime.SpecifyKind(dto.Date.Date, DateTimeKind.Utc);
        await _assignment.ValidateEligibilityAsync(dto.UserId, date);

        var dayWeight = _assignment.GetDayWeight(date);

        var duty = new Duty
        {
            Id = Guid.NewGuid(),
            GroupId = groupId,
            UserId = dto.UserId,
            User = membership.User,
            Date = date,
            IsAutoAssigned = false,
            Notes = dto.Notes,
            CreatedAt = DateTime.UtcNow
        };

        await _dutyRepository.AddAsync(duty);

        membership.Score += dayWeight;
        _membershipRepository.Update(membership);
        await _dutyRepository.SaveChangesAsync();

        await _notificationService.CreateAsync(membership.UserId, "Nöbet Atandı",
            $"{date:dd/MM/yyyy} tarihine nöbet atandınız. (Puan: +{dayWeight:F2})");

        return MapToDto(duty);
    }

    public async Task<DutyDto> AutoAssignAsync(AutoAssignDutyDto dto)
    {
        _currentGroupContext.RequireGroupId();
        _currentGroupContext.RequireAdmin();

        var date = DateTime.SpecifyKind(dto.Date.Date, DateTimeKind.Utc);

        var existing = await _dutyRepository.GetByDateAsync(date);
        if (existing.Any())
            throw new ConflictException($"{date:dd/MM/yyyy} tarihinde zaten nöbet atanmış.");

        return await AutoAssignInternalAsync(date);
    }

    private async Task<DutyDto> AutoAssignInternalAsync(DateTime date)
    {
        var groupId = _currentGroupContext.RequireGroupId();

        var selected = await _assignment.SelectMemberForDateAsync(date);
        var dayWeight = _assignment.GetDayWeight(date);

        var duty = new Duty
        {
            Id = Guid.NewGuid(),
            GroupId = groupId,
            UserId = selected.UserId,
            User = selected.User,
            Date = date,
            IsAutoAssigned = true,
            CreatedAt = DateTime.UtcNow
        };

        await _dutyRepository.AddAsync(duty);

        selected.Score += dayWeight;
        _membershipRepository.Update(selected);
        await _dutyRepository.SaveChangesAsync();

        await _notificationService.CreateAsync(selected.UserId, "Otomatik Nöbet Atandı",
            $"{date:dd/MM/yyyy} tarihine otomatik nöbet atandınız. (Puan: +{dayWeight:F2})");

        return MapToDto(duty);
    }

    public async Task DeleteAsync(Guid id)
    {
        var groupId = _currentGroupContext.RequireGroupId();
        _currentGroupContext.RequireAdmin();

        var duty = await _dutyRepository.GetByIdAsync(id)
            ?? throw new NotFoundException("Nöbet bulunamadı.");

        // Günün ağırlığı kadar puanı geri al
        double weight = _assignment.GetDayWeight(duty.Date);
        var membership = await _membershipRepository.GetAsync(groupId, duty.UserId);
        if (membership is not null && membership.Score >= weight)
        {
            membership.Score = Math.Round(membership.Score - weight, 4);
            _membershipRepository.Update(membership);
        }

        _dutyRepository.Delete(duty);
        await _dutyRepository.SaveChangesAsync();
    }

    private static DutyDto MapToDto(Duty duty) => new()
    {
        Id = duty.Id,
        UserId = duty.UserId,
        UserName = duty.User?.Name ?? string.Empty,
        Date = duty.Date,
        IsAutoAssigned = duty.IsAutoAssigned,
        Notes = duty.Notes,
        CreatedAt = duty.CreatedAt
    };
}
