using Microsoft.EntityFrameworkCore;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Enums;
using NobetSistemi.Domain.Interfaces;
using NobetSistemi.Infrastructure.Data;

namespace NobetSistemi.Infrastructure.Repositories;

public class LeaveRequestRepository : BaseRepository<LeaveRequest>, ILeaveRequestRepository
{
    public LeaveRequestRepository(AppDbContext context) : base(context) { }

    public override async Task<IEnumerable<LeaveRequest>> GetAllAsync() =>
        await _dbSet.Include(l => l.User).OrderByDescending(l => l.CreatedAt).ToListAsync();

    public async Task<IEnumerable<LeaveRequest>> GetByUserIdAsync(Guid userId) =>
        await _dbSet.Include(l => l.User)
            .Where(l => l.UserId == userId)
            .OrderByDescending(l => l.CreatedAt)
            .ToListAsync();

    public async Task<IEnumerable<LeaveRequest>> GetPendingAsync() =>
        await _dbSet.Include(l => l.User)
            .Where(l => l.Status == LeaveStatus.Pending)
            .OrderBy(l => l.CreatedAt)
            .ToListAsync();

    public async Task<bool> IsUserOnLeaveAsync(Guid userId, DateTime date) =>
        await _dbSet.AnyAsync(l =>
            l.UserId == userId &&
            l.Status == LeaveStatus.Approved &&
            l.StartDate.Date <= date.Date &&
            l.EndDate.Date >= date.Date);
}
