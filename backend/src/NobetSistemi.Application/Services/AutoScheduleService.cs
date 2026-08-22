using NobetSistemi.Application.DTOs.Duty;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Enums;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.Application.Services;

/// <summary>
/// Grupların nöbet takvimini otomatik olarak "önümüzdeki 2 ay" penceresinde
/// tutar: en az <see cref="MinMembersForAutoSchedule"/> aktif üyesi olan
/// gruplarda, üye katıldığında mevcut planı günceller; arka plan servisi de
/// zaman ilerledikçe pencereyi öne kaydırır (yeni ayı doldurur). Grupta HİÇ
/// nöbet kaydı yoksa (yepyeni grup) otomasyon devreye girmez — admin ilk
/// nöbeti kendisi atayana kadar bekler, o ilk atama (manuel ya da tek günlük
/// otomatik) yapılınca sistem devamını otomatik doldurmaya başlar. Zaten
/// çalışan (önceden nöbeti oluşmuş) gruplar bu bekleme kuralından etkilenmez.
/// </summary>
public class AutoScheduleService : IAutoScheduleService
{
    private const int MinMembersForAutoSchedule = 3;

    private readonly IGroupMembershipRepository _membershipRepository;
    private readonly IDutyRepository _dutyRepository;
    private readonly IDutyService _dutyService;
    private readonly ICurrentGroupContext _currentGroupContext;

    public AutoScheduleService(
        IGroupMembershipRepository membershipRepository,
        IDutyRepository dutyRepository,
        IDutyService dutyService,
        ICurrentGroupContext currentGroupContext)
    {
        _membershipRepository = membershipRepository;
        _dutyRepository = dutyRepository;
        _dutyService = dutyService;
        _currentGroupContext = currentGroupContext;
    }

    /// <summary>
    /// Günlük yenilemede yakın bu kadar gün sabit bırakılır — birinin nöbeti
    /// son anda, hiç habersiz değişmesin diye. Katılım anındaki ilk planlama
    /// bu tamponu kullanmaz (hemen tam güncel olmalı).
    /// </summary>
    private const int DailyRefreshFreezeDays = 2;

    public Task EnsureInitialScheduleAsync(Guid groupId) => RebalanceWindowAsync(groupId, freezeDays: 0);

    public Task RefreshScheduleAsync(Guid groupId) => RebalanceWindowAsync(groupId, freezeDays: DailyRefreshFreezeDays);

    private async Task RebalanceWindowAsync(Guid groupId, int freezeDays)
    {
        if (!await HasEnoughMembersAsync(groupId)) return;

        _currentGroupContext.SetGroup(groupId, GroupRole.Admin);

        // Grup hâlâ yepyeniyse (hiç nöbet kaydı yoksa) admin ilk nöbeti kendisi
        // atamadan otomasyon başlamaz.
        if (!await _dutyRepository.HasAnyDutyAsync()) return;

        var today = DateTime.UtcNow.Date;
        var from = today.AddDays(freezeDays);
        var endOfNextMonth = new DateTime(today.Year, today.Month, 1, 0, 0, 0, DateTimeKind.Utc)
            .AddMonths(2).AddDays(-1);

        if (from > endOfNextMonth) return;

        await _dutyService.RebalanceAsync(new RebalanceDutiesDto
        {
            FromDate = from,
            ToDate = endOfNextMonth
        });
    }

    private async Task<bool> HasEnoughMembersAsync(Guid groupId)
    {
        var activeCount = (await _membershipRepository.GetActiveMembersAsync(groupId)).Count();
        return activeCount >= MinMembersForAutoSchedule;
    }
}
