namespace NobetSistemi.Domain.Entities;

public class AdminVoteBallot
{
    public Guid Id { get; set; }
    public Guid GroupId { get; set; }
    public Group Group { get; set; } = null!;
    public Guid AdminVoteId { get; set; }
    public AdminVote AdminVote { get; set; } = null!;
    public Guid VoterUserId { get; set; }
    public User Voter { get; set; } = null!;
    public bool Approve { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
