using NobetSistemi.Domain.Enums;

namespace NobetSistemi.Application.Interfaces;

public interface ICurrentGroupContext
{
    Guid? GroupId { get; }
    GroupRole? MembershipRole { get; }
    void SetGroup(Guid groupId, GroupRole role);
    Guid RequireGroupId();
    void RequireAdmin();
}
