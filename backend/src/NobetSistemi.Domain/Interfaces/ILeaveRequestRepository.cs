using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Domain.Interfaces;

public interface ILeaveRequestRepository : IRepository<LeaveRequest>
{
    Task<IEnumerable<LeaveRequest>> GetByUserIdAsync(Guid userId);
    Task<IEnumerable<LeaveRequest>> GetPendingAsync();
    Task<bool> IsUserOnLeaveAsync(Guid userId, DateTime date);
}
