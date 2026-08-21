using NobetSistemi.Application.DTOs.Group;

namespace NobetSistemi.Application.Interfaces;

public interface IGroupService
{
    Task<GroupDto> CreateAsync(Guid userId, CreateGroupDto dto);
    Task<GroupDto> JoinAsync(Guid userId, JoinGroupDto dto);
    Task<IEnumerable<GroupDto>> GetMyGroupsAsync(Guid userId);
    Task<GroupDto> GetByIdAsync(Guid groupId, Guid requesterId);
    Task<IEnumerable<GroupMembershipDto>> GetMembersAsync(Guid groupId, Guid requesterId);
    Task<string> RegenerateJoinCodeAsync(Guid groupId, Guid requesterId, string newJoinCode);
    Task UpdateMemberAsync(Guid groupId, Guid requesterId, Guid targetUserId, UpdateMembershipDto dto);
    Task RemoveMemberAsync(Guid groupId, Guid requesterId, Guid targetUserId);
}
