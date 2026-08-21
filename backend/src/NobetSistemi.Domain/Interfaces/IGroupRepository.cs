using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Domain.Interfaces;

public interface IGroupRepository : IRepository<Group>
{
    Task<Group?> GetByJoinCodeAsync(string joinCode);
    Task<bool> JoinCodeExistsAsync(string joinCode);
}
