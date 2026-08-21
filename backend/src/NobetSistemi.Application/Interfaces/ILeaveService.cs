using NobetSistemi.Application.DTOs.Leave;

namespace NobetSistemi.Application.Interfaces;

public interface ILeaveService
{
    Task<IEnumerable<LeaveRequestDto>> GetAllAsync();
    Task<LeaveRequestDto> GetByIdAsync(Guid id);
    Task<IEnumerable<LeaveRequestDto>> GetByUserIdAsync(Guid userId);
    Task<IEnumerable<LeaveRequestDto>> GetPendingAsync();
    Task<LeaveRequestDto> CreateAsync(Guid userId, CreateLeaveRequestDto dto);
    Task<LeaveRequestDto> ReviewAsync(Guid id, Guid reviewerId, ReviewLeaveRequestDto dto);
    Task DeleteAsync(Guid id);
}
