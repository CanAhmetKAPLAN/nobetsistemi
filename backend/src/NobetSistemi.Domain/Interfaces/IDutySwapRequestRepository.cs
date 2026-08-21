using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Domain.Interfaces;

public interface IDutySwapRequestRepository : IRepository<DutySwapRequest>
{
    Task<IEnumerable<DutySwapRequest>> GetByRequesterIdAsync(Guid requesterId);
    Task<IEnumerable<DutySwapRequest>> GetByTargetUserIdAsync(Guid targetUserId);
    Task<IEnumerable<DutySwapRequest>> GetPendingAsync();
}
