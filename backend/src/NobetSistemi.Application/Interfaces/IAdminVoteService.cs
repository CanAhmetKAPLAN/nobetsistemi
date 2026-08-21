using NobetSistemi.Application.DTOs.Group;

namespace NobetSistemi.Application.Interfaces;

public interface IAdminVoteService
{
    Task<AdminVoteDto> StartAsync(Guid groupId, Guid initiatorId, StartAdminVoteDto dto);
    Task<AdminVoteDto?> GetActiveAsync(Guid groupId, Guid requesterId);
    Task<AdminVoteDto> CastVoteAsync(Guid groupId, Guid voteId, Guid voterId, CastVoteDto dto);
    Task CancelAsync(Guid groupId, Guid voteId, Guid requesterId);
}
