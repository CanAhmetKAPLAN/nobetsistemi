using Microsoft.EntityFrameworkCore;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Interfaces;
using NobetSistemi.Infrastructure.Data;

namespace NobetSistemi.Infrastructure.Repositories;

public class GroupRepository : BaseRepository<Group>, IGroupRepository
{
    public GroupRepository(AppDbContext context) : base(context) { }

    public async Task<Group?> GetByJoinCodeAsync(string joinCode) =>
        await _dbSet.FirstOrDefaultAsync(g => g.JoinCode == joinCode);

    public async Task<bool> JoinCodeExistsAsync(string joinCode) =>
        await _dbSet.AnyAsync(g => g.JoinCode == joinCode);
}
