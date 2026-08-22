using Microsoft.EntityFrameworkCore;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Interfaces;
using NobetSistemi.Infrastructure.Data;

namespace NobetSistemi.Infrastructure.Repositories;

public class DutyRepository : BaseRepository<Duty>, IDutyRepository
{
    public DutyRepository(AppDbContext context) : base(context) { }

    public override async Task<IEnumerable<Duty>> GetAllAsync() =>
        await _dbSet.Include(d => d.User).OrderBy(d => d.Date).ToListAsync();

    public async Task<IEnumerable<Duty>> GetByDateAsync(DateTime date)
    {
        var dayStart = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var dayEnd   = dayStart.AddDays(1);
        return await _dbSet.Include(d => d.User)
            .Where(d => d.Date >= dayStart && d.Date < dayEnd)
            .ToListAsync();
    }

    public async Task<IEnumerable<Duty>> GetByUserIdAsync(Guid userId) =>
        await _dbSet.Include(d => d.User)
            .Where(d => d.UserId == userId)
            .OrderBy(d => d.Date)
            .ToListAsync();

    public async Task<Duty?> GetByUserAndDateAsync(Guid userId, DateTime date)
    {
        var dayStart = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var dayEnd   = dayStart.AddDays(1);
        return await _dbSet.Include(d => d.User)
            .FirstOrDefaultAsync(d => d.UserId == userId && d.Date >= dayStart && d.Date < dayEnd);
    }

    public async Task<bool> HasDutyOnDateAsync(Guid userId, DateTime date)
    {
        var dayStart = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var dayEnd   = dayStart.AddDays(1);
        return await _dbSet.AnyAsync(d => d.UserId == userId && d.Date >= dayStart && d.Date < dayEnd);
    }

    public async Task<IEnumerable<Duty>> GetByDateRangeAsync(DateTime start, DateTime end) =>
        await _dbSet.Include(d => d.User)
            .Where(d => d.Date.Date >= start.Date && d.Date.Date <= end.Date)
            .OrderBy(d => d.Date)
            .ToListAsync();

    public async Task<IEnumerable<Duty>> GetByYearMonthAsync(int year, int month)
    {
        var start = new DateTime(year, month, 1, 0, 0, 0, DateTimeKind.Utc);
        var end = start.AddMonths(1);
        return await _dbSet.Include(d => d.User)
            .Where(d => d.Date >= start && d.Date < end)
            .OrderBy(d => d.Date)
            .ToListAsync();
    }

    public async Task<IEnumerable<(Guid UserId, string UserName, int Year, int Month, int Count)>> GetMonthlyScoresAsync()
    {
        var result = await _dbSet
            .Include(d => d.User)
            .GroupBy(d => new { d.UserId, Name = d.User!.Name, d.Date.Year, d.Date.Month })
            .Select(g => new { g.Key.UserId, g.Key.Name, g.Key.Year, g.Key.Month, Count = g.Count() })
            .OrderByDescending(x => x.Year)
            .ThenByDescending(x => x.Month)
            .ThenByDescending(x => x.Count)
            .ToListAsync();

        return result.Select(r => (r.UserId, r.Name, r.Year, r.Month, r.Count));
    }

    public async Task<int> GetWeekendDutyCountAsync(Guid userId, DateTime monthStart, DateTime monthEnd) =>
        await _dbSet.CountAsync(d =>
            d.UserId == userId &&
            d.Date >= monthStart && d.Date < monthEnd &&
            (d.Date.DayOfWeek == DayOfWeek.Saturday || d.Date.DayOfWeek == DayOfWeek.Sunday));

    public async Task<IEnumerable<Duty>> GetAllDutiesOnDateIgnoringGroupAsync(DateTime date)
    {
        var dayStart = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var dayEnd   = dayStart.AddDays(1);
        return await _dbSet.IgnoreQueryFilters().Include(d => d.User)
            .Where(d => d.Date >= dayStart && d.Date < dayEnd)
            .ToListAsync();
    }

    public async Task<DateTime?> GetLastDutyDateBeforeAsync(Guid userId, DateTime beforeDate) =>
        await _dbSet
            .Where(d => d.UserId == userId && d.Date < beforeDate.Date)
            .OrderByDescending(d => d.Date)
            .Select(d => (DateTime?)d.Date)
            .FirstOrDefaultAsync();

    public async Task<bool> HasAnyDutyAsync() =>
        await _dbSet.AnyAsync();
}
