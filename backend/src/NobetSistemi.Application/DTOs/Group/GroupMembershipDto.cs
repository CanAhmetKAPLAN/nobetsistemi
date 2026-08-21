namespace NobetSistemi.Application.DTOs.Group;

public class GroupMembershipDto
{
    public Guid UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string UserEmail { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public double Score { get; set; }
    public bool IsActive { get; set; }
    public DateTime JoinedAt { get; set; }
}
