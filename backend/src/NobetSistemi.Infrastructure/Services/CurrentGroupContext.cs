using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Enums;
using NobetSistemi.Domain.Exceptions;

namespace NobetSistemi.Infrastructure.Services;

/// <summary>
/// İstek başına (scoped) doldurulan aktif grup bağlamı.
/// GroupContextActionFilter tarafından X-Group-Id header'ı doğrulanınca set edilir.
/// </summary>
public class CurrentGroupContext : ICurrentGroupContext
{
    public Guid? GroupId { get; private set; }
    public GroupRole? MembershipRole { get; private set; }

    public void SetGroup(Guid groupId, GroupRole role)
    {
        GroupId = groupId;
        MembershipRole = role;
    }

    public Guid RequireGroupId() =>
        GroupId ?? throw new AppException("Aktif bir grup seçilmedi.", 400);

    public void RequireAdmin()
    {
        if (MembershipRole != GroupRole.Admin)
            throw new UnauthorizedException("Bu işlem için grup yöneticisi olmanız gerekir.");
    }
}
