using Microsoft.EntityFrameworkCore;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Enums;
using NobetSistemi.Domain.Interfaces;
using NobetSistemi.Infrastructure.Data;

namespace NobetSistemi.Infrastructure.Repositories;

public class GroupMembershipRepository : BaseRepository<GroupMembership>, IGroupMembershipRepository
{
    public GroupMembershipRepository(AppDbContext context) : base(context) { }

    public async Task<GroupMembership?> GetAsync(Guid groupId, Guid userId) =>
        await _dbSet.Include(m => m.User)
            .FirstOrDefaultAsync(m => m.GroupId == groupId && m.UserId == userId);

    public async Task<IEnumerable<GroupMembership>> GetByUserIdAsync(Guid userId) =>
        await _dbSet.Include(m => m.Group)
            .Where(m => m.UserId == userId && m.IsActive)
            .ToListAsync();

    public async Task<IEnumerable<GroupMembership>> GetMembersAsync(Guid groupId) =>
        await _dbSet.Include(m => m.User)
            .Where(m => m.GroupId == groupId)
            .ToListAsync();

    public async Task<IEnumerable<GroupMembership>> GetActiveMembersAsync(Guid groupId) =>
        await _dbSet.Include(m => m.User)
            .Where(m => m.GroupId == groupId && m.IsActive && m.Role == GroupRole.Member)
            .ToListAsync();

    public async Task DecayAllScoresAsync(double factor) =>
        await _dbSet.IgnoreQueryFilters()
            .ExecuteUpdateAsync(s => s.SetProperty(m => m.Score, m => m.Score * factor));
}
