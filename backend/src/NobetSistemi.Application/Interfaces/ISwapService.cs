using NobetSistemi.Application.DTOs.Swap;

namespace NobetSistemi.Application.Interfaces;

public interface ISwapService
{
    Task<IEnumerable<DutySwapRequestDto>> GetAllAsync();
    Task<DutySwapRequestDto> GetByIdAsync(Guid id);
    Task<IEnumerable<DutySwapRequestDto>> GetByRequesterIdAsync(Guid requesterId);
    Task<IEnumerable<DutySwapRequestDto>> GetIncomingAsync(Guid targetUserId);
    Task<IEnumerable<DutySwapRequestDto>> GetPendingAsync();
    Task<DutySwapRequestDto> CreateAsync(Guid requesterId, CreateSwapRequestDto dto);
    Task<DutySwapRequestDto> ReviewAsync(Guid id, Guid reviewerId, ReviewSwapRequestDto dto);
    Task CancelAsync(Guid id, Guid userId);
}
