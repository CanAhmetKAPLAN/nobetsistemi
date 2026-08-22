using NobetSistemi.Application.DTOs.Group;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Enums;
using NobetSistemi.Domain.Exceptions;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.Application.Services;

public class GroupService : IGroupService
{
    private readonly IGroupRepository _groupRepository;
    private readonly IGroupMembershipRepository _membershipRepository;
    private readonly IUserRepository _userRepository;

    public GroupService(
        IGroupRepository groupRepository,
        IGroupMembershipRepository membershipRepository,
        IUserRepository userRepository)
    {
        _groupRepository = groupRepository;
        _membershipRepository = membershipRepository;
        _userRepository = userRepository;
    }

    public async Task<GroupDto> CreateAsync(Guid userId, CreateGroupDto dto)
    {
        var code = dto.JoinCode.Trim();
        if (await _groupRepository.JoinCodeExistsAsync(code))
            throw new ConflictException("Bu katılım kodu zaten kullanılıyor.");

        _ = await _userRepository.GetByIdAsync(userId)
            ?? throw new NotFoundException("Kullanıcı bulunamadı.");

        var group = new Group
        {
            Id = Guid.NewGuid(),
            Name = dto.Name.Trim(),
            JoinCode = code,
            CreatedById = userId,
            CreatedAt = DateTime.UtcNow
        };
        await _groupRepository.AddAsync(group);

        var membership = new GroupMembership
        {
            Id = Guid.NewGuid(),
            GroupId = group.Id,
            UserId = userId,
            Role = GroupRole.Admin,
            Score = 0,
            IsActive = true,
            JoinedAt = DateTime.UtcNow
        };
        await _membershipRepository.AddAsync(membership);
        await _groupRepository.SaveChangesAsync();

        return MapToDto(group, membership.Role, 1);
    }

    public async Task<GroupDto> JoinAsync(Guid userId, JoinGroupDto dto)
    {
        var code = dto.JoinCode.Trim();
        var group = await _groupRepository.GetByJoinCodeAsync(code)
            ?? throw new NotFoundException("Geçersiz katılım kodu.");

        var existing = await _membershipRepository.GetAsync(group.Id, userId);
        if (existing is not null)
            throw new ConflictException("Bu gruba zaten üyesiniz.");

        var currentMembers = (await _membershipRepository.GetMembersAsync(group.Id))
            .Where(m => m.IsActive)
            .ToList();

        var membership = new GroupMembership
        {
            Id = Guid.NewGuid(),
            GroupId = group.Id,
            UserId = userId,
            Role = GroupRole.Member,
            Score = ComputeJoinStartScore(currentMembers),
            IsActive = true,
            JoinedAt = DateTime.UtcNow
        };
        await _membershipRepository.AddAsync(membership);
        await _membershipRepository.SaveChangesAsync();

        return MapToDto(group, membership.Role, currentMembers.Count + 1);
    }

    /// <summary>
    /// Sonradan katılan bir üye 0 puanla başlarsa, atama algoritması onu
    /// grup ortalaması yakalanana kadar art arda seçer — bu haksız bir yük
    /// oluşturur. Grubun mevcut ortalaması 1'in üzerindeyse yeni üye, puan
    /// adımlarının (0.25/0.50/0.75/1.00) BİR ALTINA yuvarlanmış ortalamayla
    /// başlar (en yakına değil — üyeye küçük bir avantaj bırakmak için).
    /// Ortalama 1 veya altındaysa grup zaten yeni sayılır, 0'dan başlamak
    /// sorun yaratmaz.
    /// </summary>
    private static double ComputeJoinStartScore(List<GroupMembership> currentMembers)
    {
        if (currentMembers.Count == 0) return 0;

        var avg = currentMembers.Average(m => m.Score);
        if (avg <= 1) return 0;

        var steps = Math.Floor(Math.Round(avg / 0.25, 6));
        return Math.Round(steps * 0.25, 2);
    }

    public async Task<IEnumerable<GroupDto>> GetMyGroupsAsync(Guid userId)
    {
        var memberships = await _membershipRepository.GetByUserIdAsync(userId);
        var result = new List<GroupDto>();
        foreach (var m in memberships)
        {
            var memberCount = (await _membershipRepository.GetMembersAsync(m.GroupId)).Count();
            result.Add(MapToDto(m.Group, m.Role, memberCount));
        }
        return result;
    }

    public async Task<GroupDto> GetByIdAsync(Guid groupId, Guid requesterId)
    {
        var membership = await _membershipRepository.GetAsync(groupId, requesterId)
            ?? throw new UnauthorizedException("Bu gruba üye değilsiniz.");

        var group = await _groupRepository.GetByIdAsync(groupId)
            ?? throw new NotFoundException("Grup bulunamadı.");

        var memberCount = (await _membershipRepository.GetMembersAsync(groupId)).Count();
        return MapToDto(group, membership.Role, memberCount);
    }

    public async Task<IEnumerable<GroupMembershipDto>> GetMembersAsync(Guid groupId, Guid requesterId)
    {
        _ = await _membershipRepository.GetAsync(groupId, requesterId)
            ?? throw new UnauthorizedException("Bu gruba üye değilsiniz.");

        var members = await _membershipRepository.GetMembersAsync(groupId);
        return members
            .OrderByDescending(m => m.Score)
            .Select(MapMembershipToDto);
    }

    public async Task<string> RegenerateJoinCodeAsync(Guid groupId, Guid requesterId, string newJoinCode)
    {
        await RequireGroupAdminAsync(groupId, requesterId);

        var code = newJoinCode.Trim();
        if (await _groupRepository.JoinCodeExistsAsync(code))
            throw new ConflictException("Bu katılım kodu zaten kullanılıyor.");

        var group = await _groupRepository.GetByIdAsync(groupId)
            ?? throw new NotFoundException("Grup bulunamadı.");

        group.JoinCode = code;
        _groupRepository.Update(group);
        await _groupRepository.SaveChangesAsync();
        return code;
    }

    public async Task UpdateMemberAsync(Guid groupId, Guid requesterId, Guid targetUserId, UpdateMembershipDto dto)
    {
        await RequireGroupAdminAsync(groupId, requesterId);

        var target = await _membershipRepository.GetAsync(groupId, targetUserId)
            ?? throw new NotFoundException("Üye bulunamadı.");

        GroupRole? newRole = null;
        if (dto.Role is not null)
        {
            if (!Enum.TryParse<GroupRole>(dto.Role, true, out var role))
                throw new AppException("Geçersiz rol.");
            newRole = role;
        }

        var wasActiveAdmin = target.Role == GroupRole.Admin && target.IsActive;
        var willBeActiveAdmin = (newRole ?? target.Role) == GroupRole.Admin && (dto.IsActive ?? target.IsActive);
        if (wasActiveAdmin && !willBeActiveAdmin)
            await EnsureNotLastActiveAdminAsync(groupId, targetUserId);

        if (newRole is not null) target.Role = newRole.Value;
        if (dto.IsActive is not null) target.IsActive = dto.IsActive.Value;

        _membershipRepository.Update(target);
        await _membershipRepository.SaveChangesAsync();
    }

    public async Task RemoveMemberAsync(Guid groupId, Guid requesterId, Guid targetUserId)
    {
        await RequireGroupAdminAsync(groupId, requesterId);

        var target = await _membershipRepository.GetAsync(groupId, targetUserId)
            ?? throw new NotFoundException("Üye bulunamadı.");

        if (target.Role == GroupRole.Admin && target.IsActive)
            await EnsureNotLastActiveAdminAsync(groupId, targetUserId);

        _membershipRepository.Delete(target);
        await _membershipRepository.SaveChangesAsync();
    }

    private async Task RequireGroupAdminAsync(Guid groupId, Guid requesterId)
    {
        var requesterMembership = await _membershipRepository.GetAsync(groupId, requesterId);
        if (requesterMembership is null || requesterMembership.Role != GroupRole.Admin)
            throw new UnauthorizedException("Bu işlem için grup yöneticisi olmanız gerekir.");
    }

    /// <summary>Grubun her zaman en az bir aktif admini olmasını garanti eder.</summary>
    private async Task EnsureNotLastActiveAdminAsync(Guid groupId, Guid excludingUserId)
    {
        var members = await _membershipRepository.GetMembersAsync(groupId);
        bool anotherActiveAdminExists = members.Any(m =>
            m.UserId != excludingUserId && m.Role == GroupRole.Admin && m.IsActive);

        if (!anotherActiveAdminExists)
            throw new AppException("Grubun tek adminini bu şekilde çıkaramazsınız. Önce başka birine adminlik verin.");
    }

    private static GroupDto MapToDto(Group group, GroupRole myRole, int memberCount) => new()
    {
        Id = group.Id,
        Name = group.Name,
        MemberCount = memberCount,
        MyRole = myRole.ToString(),
        CreatedAt = group.CreatedAt
    };

    private static GroupMembershipDto MapMembershipToDto(GroupMembership m) => new()
    {
        UserId = m.UserId,
        UserName = m.User?.Name ?? string.Empty,
        UserEmail = m.User?.Email ?? string.Empty,
        Role = m.Role.ToString(),
        Score = m.Score,
        IsActive = m.IsActive,
        JoinedAt = m.JoinedAt
    };
}
