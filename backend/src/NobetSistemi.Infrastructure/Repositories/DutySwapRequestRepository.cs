using Microsoft.EntityFrameworkCore;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Enums;
using NobetSistemi.Domain.Interfaces;
using NobetSistemi.Infrastructure.Data;

namespace NobetSistemi.Infrastructure.Repositories;

public class DutySwapRequestRepository : BaseRepository<DutySwapRequest>, IDutySwapRequestRepository
{
    public DutySwapRequestRepository(AppDbContext context) : base(context) { }

    public override async Task<DutySwapRequest?> GetByIdAsync(Guid id) =>
        await _dbSet
            .Include(s => s.Requester)
            .Include(s => s.TargetUser)
            .Include(s => s.RequesterDuty)
            .Include(s => s.TargetDuty)
            .FirstOrDefaultAsync(s => s.Id == id);

    public override async Task<IEnumerable<DutySwapRequest>> GetAllAsync() =>
        await _dbSet
            .Include(s => s.Requester)
            .Include(s => s.TargetUser)
            .Include(s => s.RequesterDuty)
            .Include(s => s.TargetDuty)
            .OrderByDescending(s => s.CreatedAt)
            .ToListAsync();

    public async Task<IEnumerable<DutySwapRequest>> GetByRequesterIdAsync(Guid requesterId) =>
        await _dbSet
            .Include(s => s.Requester)
            .Include(s => s.TargetUser)
            .Include(s => s.RequesterDuty)
            .Include(s => s.TargetDuty)
            .Where(s => s.RequesterId == requesterId)
            .OrderByDescending(s => s.CreatedAt)
            .ToListAsync();

    public async Task<IEnumerable<DutySwapRequest>> GetByTargetUserIdAsync(Guid targetUserId) =>
        await _dbSet
            .Include(s => s.Requester)
            .Include(s => s.TargetUser)
            .Include(s => s.RequesterDuty)
            .Include(s => s.TargetDuty)
            .Where(s => s.TargetUserId == targetUserId)
            .OrderByDescending(s => s.CreatedAt)
            .ToListAsync();

    public async Task<IEnumerable<DutySwapRequest>> GetPendingAsync() =>
        await _dbSet
            .Include(s => s.Requester)
            .Include(s => s.TargetUser)
            .Include(s => s.RequesterDuty)
            .Include(s => s.TargetDuty)
            .Where(s => s.Status == SwapStatus.Pending)
            .OrderBy(s => s.CreatedAt)
            .ToListAsync();
}
