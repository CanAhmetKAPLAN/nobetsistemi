using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Exceptions;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.Application.Services;

/// <summary>
/// GÜN PUANLARI
///   Pzt-Per : 0.25  |  Cuma : 0.50  |  Cumartesi : 1.00  |  Pazar : 0.75
///
/// SEÇİM MANTIĞI
///   1. Aktif grubun izinsiz, ardışık nöbet almamış üyeleri filtrelenir.
///   2. MaxDroughtDays'den uzun süredir nöbet almayan biri varsa (hiç
///      almamışsa öncelikli), havuz puan farkı gözetmeksizin sadece o
///      üye(ler)le sınırlanır — kimse haftalarca sırası gelmeden bekleyemez.
///   3. En düşük TotalScore'a sahip üye seçilir.
///   4. Eşitlikte, en uzun süredir nöbet tutmayan üye kazanır (deterministik —
///      rastgele değil, böylece yeniden hesaplama gereksiz karışıklık yaratmaz).
///
/// HAFTA SONU DENGESİ
///   Cumartesi/Pazar için o ay kaç kez hafta sonu nöbeti tutulduğu,
///   günün ağırlığı kadar effective score'a eklenir.
///   Örnek: 1 hafta sonu nöbeti olan üyenin etkili skoru += 0.75 (Pazar)
///
/// AYLIK DECAY
///   MonthEndDecayHostedService her ay başında TotalScore *= 0.80 uygular.
///
/// Aday havuzu artık sadece o an X-Group-Id header'ı ile seçilmiş aktif
/// grubun üyeleriyle sınırlıdır (bkz. ICurrentGroupContext).
/// </summary>
public class DutyAssignmentService : IDutyAssignmentService
{
    /// <summary>Bir üye, uygun olduğu sürece en fazla bu kadar gün nöbetsiz kalabilir.</summary>
    private const int MaxDroughtDays = 14;

    private static readonly Dictionary<DayOfWeek, double> DayWeights = new()
    {
        [DayOfWeek.Monday]    = 0.25,
        [DayOfWeek.Tuesday]   = 0.25,
        [DayOfWeek.Wednesday] = 0.25,
        [DayOfWeek.Thursday]  = 0.25,
        [DayOfWeek.Friday]    = 0.50,
        [DayOfWeek.Saturday]  = 1.00,
        [DayOfWeek.Sunday]    = 0.75,
    };

    private readonly IDutyRepository _dutyRepository;
    private readonly IGroupMembershipRepository _membershipRepository;
    private readonly ILeaveRequestRepository _leaveRepository;
    private readonly ICurrentGroupContext _currentGroupContext;

    public DutyAssignmentService(
        IDutyRepository dutyRepository,
        IGroupMembershipRepository membershipRepository,
        ILeaveRequestRepository leaveRepository,
        ICurrentGroupContext currentGroupContext)
    {
        _dutyRepository = dutyRepository;
        _membershipRepository = membershipRepository;
        _leaveRepository = leaveRepository;
        _currentGroupContext = currentGroupContext;
    }

    public double GetDayWeight(DateTime date) =>
        DayWeights.TryGetValue(date.DayOfWeek, out var w) ? w : 0.25;

    /// <summary>
    /// Aktif grup içinde verilen tarih için en uygun üyeyi seçer.
    /// </summary>
    public async Task<GroupMembership> SelectMemberForDateAsync(DateTime date)
    {
        var groupId = _currentGroupContext.RequireGroupId();

        var activeMembers = (await _membershipRepository.GetActiveMembersAsync(groupId)).ToList();

        if (activeMembers.Count == 0)
            throw new AppException("Aktif üye bulunamadı.");

        // ─── Uygunluk filtresi ────────────────────────────────────────────────
        var eligible = new List<GroupMembership>();
        foreach (var member in activeMembers)
        {
            if (await _leaveRepository.IsUserOnLeaveAsync(member.UserId, date)) continue;
            if (await _dutyRepository.HasDutyOnDateAsync(member.UserId, date.AddDays(-1))) continue;
            eligible.Add(member);
        }

        // Herkes ardışık kısıtta sıkışmışsa kısıtı kaldır (küçük ekip güvencesi)
        if (eligible.Count == 0)
        {
            foreach (var member in activeMembers)
            {
                if (await _leaveRepository.IsUserOnLeaveAsync(member.UserId, date)) continue;
                eligible.Add(member);
            }
        }

        if (eligible.Count == 0)
            throw new AppException("Uygun üye bulunamadı: tüm üyeler bu tarihte izinli.");

        // ─── Kuraklık sınırı ──────────────────────────────────────────────────
        // Salt "en düşük puan kazanır" kuralı, aradaki fark küçük bile olsa
        // birinin haftalarca sırasının hiç gelmemesine yol açabilir (ör. yeni
        // katılan bir üye, üstünde birkaç kişi varsa onlar birbirini art-ardalık
        // kuralıyla dengeleyip haftalarca öne geçebiliyor). Bu yüzden, uygun
        // üyelerden biri MaxDroughtDays'den fazladır hiç nöbet almadıysa
        // (hiç almamışsa öncelikli), puanı ne olursa olsun havuz sadece o
        // "sırası gelmiş" üyelerle sınırlanır.
        var overdue = new List<GroupMembership>();
        foreach (var member in eligible)
        {
            var lastDuty = await _dutyRepository.GetLastDutyDateBeforeAsync(member.UserId, date);
            if (lastDuty is null || (date - lastDuty.Value).TotalDays > MaxDroughtDays)
                overdue.Add(member);
        }
        if (overdue.Count > 0)
            eligible = overdue;

        // ─── Hafta sonu dengesi ───────────────────────────────────────────────
        bool isWeekend = date.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday;
        double dayWeight = GetDayWeight(date);

        var monthStart = new DateTime(date.Year, date.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var monthEnd   = monthStart.AddMonths(1);

        var scored = new List<(GroupMembership Member, double EffectiveScore)>();
        foreach (var member in eligible)
        {
            double effective = member.Score;

            if (isWeekend)
            {
                int weekendThisMonth = await _dutyRepository
                    .GetWeekendDutyCountAsync(member.UserId, monthStart, monthEnd);

                // Her önceki hafta sonu nöbeti için günün ağırlığı kadar ceza
                effective += weekendThisMonth * dayWeight;
            }

            scored.Add((member, effective));
        }

        // ─── En düşük effective score → deterministik tie-break ──────────────
        // Eşitlikte rastgele seçim yerine "en uzun süredir nöbet tutmayan"
        // üye kazanır (hiç tutmamışsa öncelikli). Bu sayede aynı durumda
        // (puanlar/üyeler değişmeden) yeniden çalıştırıldığında hep aynı
        // sonuç çıkar — günlük otomatik yeniden dengeleme, gerçekte hiçbir
        // şey değişmediğinde nöbetleri gereksiz yere karıştırmaz.
        // Kayan noktalı toplama/çıkarmalardan doğan mikroskobik farklar
        // "eşit" puanları eşit olarak tanımayı engellemesin diye epsilon
        // toleranslı karşılaştırma kullanılır.
        const double scoreEpsilon = 0.0001;
        double minScore = scored.Min(x => x.EffectiveScore);
        var candidates  = scored.Where(x => Math.Abs(x.EffectiveScore - minScore) < scoreEpsilon)
            .Select(x => x.Member).ToList();

        if (candidates.Count == 1) return candidates[0];

        var withLastDuty = new List<(GroupMembership Member, DateTime LastDuty)>();
        foreach (var member in candidates)
        {
            var lastDuty = await _dutyRepository.GetLastDutyDateBeforeAsync(member.UserId, date);
            withLastDuty.Add((member, lastDuty ?? DateTime.MinValue));
        }

        return withLastDuty
            .OrderBy(x => x.LastDuty)
            .ThenBy(x => x.Member.UserId)
            .First()
            .Member;
    }

    /// <summary>
    /// Manuel atama öncesi uygunluk doğrulaması.
    /// </summary>
    public async Task ValidateEligibilityAsync(Guid userId, DateTime date)
    {
        if (await _leaveRepository.IsUserOnLeaveAsync(userId, date))
            throw new AppException("Kullanıcı bu tarihte izinli.");

        if (await _dutyRepository.HasDutyOnDateAsync(userId, date.AddDays(-1)))
            throw new AppException(
                "Kullanıcı önceki gün nöbet tuttu. Ardışık nöbet yasaktır.");
    }
}
