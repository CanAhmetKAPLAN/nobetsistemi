using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Domain.Interfaces;

public interface IAdminVoteRepository : IRepository<AdminVote>
{
    Task<AdminVote?> GetPendingByGroupAsync(Guid groupId);
    Task<AdminVoteBallot?> GetBallotAsync(Guid adminVoteId, Guid voterId);
    Task AddBallotAsync(AdminVoteBallot ballot);
    void UpdateBallot(AdminVoteBallot ballot);
}
