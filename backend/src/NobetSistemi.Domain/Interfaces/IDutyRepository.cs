using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Domain.Interfaces;

public interface IDutyRepository : IRepository<Duty>
{
    Task<IEnumerable<Duty>> GetByDateAsync(DateTime date);
    Task<IEnumerable<Duty>> GetByUserIdAsync(Guid userId);
    Task<Duty?> GetByUserAndDateAsync(Guid userId, DateTime date);
    Task<bool> HasDutyOnDateAsync(Guid userId, DateTime date);
    Task<IEnumerable<Duty>> GetByDateRangeAsync(DateTime start, DateTime end);
    Task<IEnumerable<Duty>> GetByYearMonthAsync(int year, int month);
    Task<IEnumerable<(Guid UserId, string UserName, int Year, int Month, int Count)>> GetMonthlyScoresAsync();
    Task<int> GetWeekendDutyCountAsync(Guid userId, DateTime monthStart, DateTime monthEnd);
    Task<IEnumerable<Duty>> GetAllDutiesOnDateIgnoringGroupAsync(DateTime date);
}
