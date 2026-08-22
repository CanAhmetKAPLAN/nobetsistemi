using NobetSistemi.Application.DTOs.Duty;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Enums;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.Application.Services;

/// <summary>
/// Grupların nöbet takvimini otomatik olarak "önümüzdeki 2 ay" penceresinde
/// tutar: en az <see cref="MinMembersForAutoSchedule"/> aktif üyesi olan
/// gruplarda, üye katıldığında mevcut planı günceller; arka plan servisi de
/// zaman ilerledikçe pencereyi öne kaydırır (yeni ayı doldurur).
/// </summary>
public class AutoScheduleService : IAutoScheduleService
{
    private const int MinMembersForAutoSchedule = 3;

    private readonly IGroupMembershipRepository _membershipRepository;
    private readonly IDutyService _dutyService;
    private readonly ICurrentGroupContext _currentGroupContext;

    public AutoScheduleService(
        IGroupMembershipRepository membershipRepository,
        IDutyService dutyService,
        ICurrentGroupContext currentGroupContext)
    {
        _membershipRepository = membershipRepository;
        _dutyService = dutyService;
        _currentGroupContext = currentGroupContext;
    }

    public async Task EnsureInitialScheduleAsync(Guid groupId)
    {
        if (!await HasEnoughMembersAsync(groupId)) return;

        _currentGroupContext.SetGroup(groupId, GroupRole.Admin);

        var today = DateTime.UtcNow.Date;
        var endOfNextMonth = new DateTime(today.Year, today.Month, 1, 0, 0, 0, DateTimeKind.Utc)
            .AddMonths(2).AddDays(-1);

        await _dutyService.RebalanceAsync(new RebalanceDutiesDto
        {
            FromDate = today,
            ToDate = endOfNextMonth
        });
    }

    public async Task ExtendRollingScheduleAsync(Guid groupId)
    {
        if (!await HasEnoughMembersAsync(groupId)) return;

        _currentGroupContext.SetGroup(groupId, GroupRole.Admin);

        var today = DateTime.UtcNow.Date;
        var nextMonth = today.AddMonths(1);

        await _dutyService.AutoFillMonthAsync(today.Year, today.Month);
        await _dutyService.AutoFillMonthAsync(nextMonth.Year, nextMonth.Month);
    }

    private async Task<bool> HasEnoughMembersAsync(Guid groupId)
    {
        var activeCount = (await _membershipRepository.GetActiveMembersAsync(groupId)).Count();
        return activeCount >= MinMembersForAutoSchedule;
    }
}
