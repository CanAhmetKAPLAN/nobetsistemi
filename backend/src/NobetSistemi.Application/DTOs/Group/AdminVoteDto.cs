namespace NobetSistemi.Application.DTOs.Group;

public class AdminVoteDto
{
    public Guid Id { get; set; }
    public Guid CandidateUserId { get; set; }
    public string CandidateName { get; set; } = string.Empty;
    public Guid InitiatedById { get; set; }
    public string InitiatedByName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int YesCount { get; set; }
    public int NoCount { get; set; }
    public int ActiveMemberCount { get; set; }
    public int RequiredYesCount { get; set; }
    public bool? MyVote { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ResolvedAt { get; set; }
}
