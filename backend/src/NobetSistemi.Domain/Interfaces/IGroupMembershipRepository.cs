using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Domain.Interfaces;

public interface IGroupMembershipRepository : IRepository<GroupMembership>
{
    Task<GroupMembership?> GetAsync(Guid groupId, Guid userId);
    Task<IEnumerable<GroupMembership>> GetByUserIdAsync(Guid userId);
    Task<IEnumerable<GroupMembership>> GetMembersAsync(Guid groupId);
    Task<IEnumerable<GroupMembership>> GetActiveMembersAsync(Guid groupId);
    Task DecayAllScoresAsync(double factor);
}
