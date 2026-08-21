using Microsoft.EntityFrameworkCore;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Enums;
using NobetSistemi.Domain.Interfaces;
using NobetSistemi.Infrastructure.Data;

namespace NobetSistemi.Infrastructure.Repositories;

public class AdminVoteRepository : BaseRepository<AdminVote>, IAdminVoteRepository
{
    public AdminVoteRepository(AppDbContext context) : base(context) { }

    public override async Task<AdminVote?> GetByIdAsync(Guid id) =>
        await _dbSet
            .Include(v => v.Candidate)
            .Include(v => v.InitiatedBy)
            .Include(v => v.Ballots)
            .FirstOrDefaultAsync(v => v.Id == id);

    public async Task<AdminVote?> GetPendingByGroupAsync(Guid groupId) =>
        await _dbSet
            .Include(v => v.Candidate)
            .Include(v => v.InitiatedBy)
            .Include(v => v.Ballots)
            .FirstOrDefaultAsync(v => v.GroupId == groupId && v.Status == AdminVoteStatus.Pending);

    public async Task<AdminVoteBallot?> GetBallotAsync(Guid adminVoteId, Guid voterId) =>
        await _context.Set<AdminVoteBallot>()
            .FirstOrDefaultAsync(b => b.AdminVoteId == adminVoteId && b.VoterUserId == voterId);

    public async Task AddBallotAsync(AdminVoteBallot ballot) =>
        await _context.Set<AdminVoteBallot>().AddAsync(ballot);

    public void UpdateBallot(AdminVoteBallot ballot) =>
        _context.Set<AdminVoteBallot>().Update(ballot);
}
