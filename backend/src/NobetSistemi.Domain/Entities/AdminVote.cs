using NobetSistemi.Domain.Enums;

namespace NobetSistemi.Domain.Entities;

/// <summary>
/// Bir grup üyesini admin yapmak için başlatılan onay/red oylaması.
/// Adminlik verir, kimseyi adminlikten düşürmez (çoklu admin modeli).
/// </summary>
public class AdminVote
{
    public Guid Id { get; set; }
    public Guid GroupId { get; set; }
    public Group Group { get; set; } = null!;
    public Guid CandidateUserId { get; set; }
    public User Candidate { get; set; } = null!;
    public Guid InitiatedById { get; set; }
    public User InitiatedBy { get; set; } = null!;
    public AdminVoteStatus Status { get; set; } = AdminVoteStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ResolvedAt { get; set; }

    public ICollection<AdminVoteBallot> Ballots { get; set; } = new List<AdminVoteBallot>();
}
