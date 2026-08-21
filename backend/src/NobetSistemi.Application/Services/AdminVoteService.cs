using NobetSistemi.Application.DTOs.Group;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Enums;
using NobetSistemi.Domain.Exceptions;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.Application.Services;

/// <summary>
/// Bir grup üyesini admin yapmak için onay/red oylaması. Herhangi bir aktif
/// üye oylama başlatabilir (aday otomatik "evet" oyu alır), tüm aktif üyeler
/// oy kullanabilir. Aktif üyelerin salt çoğunluğu "evet" derse aday admin
/// olur (mevcut adminler adminlikten düşmez — çoklu admin modeli).
/// </summary>
public class AdminVoteService : IAdminVoteService
{
    private readonly IAdminVoteRepository _voteRepository;
    private readonly IGroupMembershipRepository _membershipRepository;
    private readonly INotificationService _notificationService;

    public AdminVoteService(
        IAdminVoteRepository voteRepository,
        IGroupMembershipRepository membershipRepository,
        INotificationService notificationService)
    {
        _voteRepository = voteRepository;
        _membershipRepository = membershipRepository;
        _notificationService = notificationService;
    }

    public async Task<AdminVoteDto> StartAsync(Guid groupId, Guid initiatorId, StartAdminVoteDto dto)
    {
        var initiatorMembership = await _membershipRepository.GetAsync(groupId, initiatorId);
        if (initiatorMembership is null || !initiatorMembership.IsActive)
            throw new UnauthorizedException("Bu gruba üye değilsiniz.");

        var candidateMembership = await _membershipRepository.GetAsync(groupId, dto.CandidateUserId)
            ?? throw new NotFoundException("Aday bu grubun üyesi değil.");

        if (!candidateMembership.IsActive)
            throw new AppException("Pasif bir üye adminliğe aday gösterilemez.");

        if (candidateMembership.Role == GroupRole.Admin)
            throw new AppException("Bu kullanıcı zaten admin.");

        if (await _voteRepository.GetPendingByGroupAsync(groupId) is not null)
            throw new ConflictException("Bu grupta zaten aktif bir oylama var.");

        var vote = new AdminVote
        {
            Id = Guid.NewGuid(),
            GroupId = groupId,
            CandidateUserId = dto.CandidateUserId,
            InitiatedById = initiatorId,
            Status = AdminVoteStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
        await _voteRepository.AddAsync(vote);
        await _voteRepository.SaveChangesAsync();

        // Oylamayı başlatanın oyu otomatik "evet" sayılır.
        await _voteRepository.AddBallotAsync(new AdminVoteBallot
        {
            Id = Guid.NewGuid(),
            GroupId = groupId,
            AdminVoteId = vote.Id,
            VoterUserId = initiatorId,
            Approve = true,
            CreatedAt = DateTime.UtcNow
        });
        await _voteRepository.SaveChangesAsync();

        var resolved = await ResolveIfNeededAsync(vote.Id, groupId);
        return await MapToDtoAsync(resolved, groupId, initiatorId);
    }

    public async Task<AdminVoteDto?> GetActiveAsync(Guid groupId, Guid requesterId)
    {
        if (await _membershipRepository.GetAsync(groupId, requesterId) is null)
            throw new UnauthorizedException("Bu gruba üye değilsiniz.");

        var vote = await _voteRepository.GetPendingByGroupAsync(groupId);
        return vote is null ? null : await MapToDtoAsync(vote, groupId, requesterId);
    }

    public async Task<AdminVoteDto> CastVoteAsync(Guid groupId, Guid voteId, Guid voterId, CastVoteDto dto)
    {
        var voterMembership = await _membershipRepository.GetAsync(groupId, voterId);
        if (voterMembership is null || !voterMembership.IsActive)
            throw new UnauthorizedException("Bu gruba üye değilsiniz.");

        var vote = await _voteRepository.GetByIdAsync(voteId);
        if (vote is null || vote.GroupId != groupId)
            throw new NotFoundException("Oylama bulunamadı.");

        if (vote.Status != AdminVoteStatus.Pending)
            throw new AppException("Bu oylama artık aktif değil.");

        var existingBallot = await _voteRepository.GetBallotAsync(voteId, voterId);
        if (existingBallot is not null)
        {
            existingBallot.Approve = dto.Approve;
            _voteRepository.UpdateBallot(existingBallot);
        }
        else
        {
            await _voteRepository.AddBallotAsync(new AdminVoteBallot
            {
                Id = Guid.NewGuid(),
                GroupId = groupId,
                AdminVoteId = voteId,
                VoterUserId = voterId,
                Approve = dto.Approve,
                CreatedAt = DateTime.UtcNow
            });
        }
        await _voteRepository.SaveChangesAsync();

        var resolved = await ResolveIfNeededAsync(voteId, groupId);
        return await MapToDtoAsync(resolved, groupId, voterId);
    }

    public async Task CancelAsync(Guid groupId, Guid voteId, Guid requesterId)
    {
        var requesterMembership = await _membershipRepository.GetAsync(groupId, requesterId)
            ?? throw new UnauthorizedException("Bu gruba üye değilsiniz.");

        var vote = await _voteRepository.GetByIdAsync(voteId);
        if (vote is null || vote.GroupId != groupId)
            throw new NotFoundException("Oylama bulunamadı.");

        if (vote.Status != AdminVoteStatus.Pending)
            throw new AppException("Bu oylama artık aktif değil.");

        bool canCancel = vote.InitiatedById == requesterId || requesterMembership.Role == GroupRole.Admin;
        if (!canCancel)
            throw new UnauthorizedException("Bu oylamayı iptal etme yetkiniz yok.");

        vote.Status = AdminVoteStatus.Cancelled;
        vote.ResolvedAt = DateTime.UtcNow;
        _voteRepository.Update(vote);
        await _voteRepository.SaveChangesAsync();
    }

    /// <summary>
    /// Oyları sayar; salt çoğunluk sağlandıysa adayı admin yapıp oylamayı
    /// "Passed" olarak kapatır, matematiksel olarak imkansız hale geldiyse
    /// "Rejected" olarak kapatır. Aksi halde "Pending" kalır.
    /// </summary>
    private async Task<AdminVote> ResolveIfNeededAsync(Guid voteId, Guid groupId)
    {
        var vote = await _voteRepository.GetByIdAsync(voteId)
            ?? throw new NotFoundException("Oylama bulunamadı.");

        if (vote.Status != AdminVoteStatus.Pending) return vote;

        var activeMembers = (await _membershipRepository.GetMembersAsync(groupId))
            .Where(m => m.IsActive)
            .ToList();
        int activeCount = activeMembers.Count;
        int requiredYes = activeCount / 2 + 1;

        int yes = vote.Ballots.Count(b => b.Approve);
        int no = vote.Ballots.Count(b => !b.Approve);
        int maxPossibleYes = activeCount - no;

        if (yes >= requiredYes)
        {
            var candidateMembership = activeMembers.FirstOrDefault(m => m.UserId == vote.CandidateUserId);
            if (candidateMembership is not null && candidateMembership.Role != GroupRole.Admin)
            {
                candidateMembership.Role = GroupRole.Admin;
                _membershipRepository.Update(candidateMembership);
                await _notificationService.CreateAsync(candidateMembership.UserId,
                    "👑 Admin Oldunuz",
                    "Grup üyelerinin oylamasıyla admin yetkisi kazandınız.");
            }

            vote.Status = AdminVoteStatus.Passed;
            vote.ResolvedAt = DateTime.UtcNow;
            _voteRepository.Update(vote);
            await _voteRepository.SaveChangesAsync();
        }
        else if (maxPossibleYes < requiredYes)
        {
            vote.Status = AdminVoteStatus.Rejected;
            vote.ResolvedAt = DateTime.UtcNow;
            _voteRepository.Update(vote);
            await _voteRepository.SaveChangesAsync();
        }

        return vote;
    }

    private async Task<AdminVoteDto> MapToDtoAsync(AdminVote vote, Guid groupId, Guid requesterId)
    {
        var activeCount = (await _membershipRepository.GetMembersAsync(groupId)).Count(m => m.IsActive);
        var myBallot = vote.Ballots.FirstOrDefault(b => b.VoterUserId == requesterId);

        return new AdminVoteDto
        {
            Id = vote.Id,
            CandidateUserId = vote.CandidateUserId,
            CandidateName = vote.Candidate?.Name ?? string.Empty,
            InitiatedById = vote.InitiatedById,
            InitiatedByName = vote.InitiatedBy?.Name ?? string.Empty,
            Status = vote.Status.ToString(),
            YesCount = vote.Ballots.Count(b => b.Approve),
            NoCount = vote.Ballots.Count(b => !b.Approve),
            ActiveMemberCount = activeCount,
            RequiredYesCount = activeCount / 2 + 1,
            MyVote = myBallot?.Approve,
            CreatedAt = vote.CreatedAt,
            ResolvedAt = vote.ResolvedAt
        };
    }
}
