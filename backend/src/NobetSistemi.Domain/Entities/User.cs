namespace NobetSistemi.Domain.Entities;

public class User
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string? FcmToken { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<GroupMembership> Memberships { get; set; } = new List<GroupMembership>();
    public ICollection<Duty> Duties { get; set; } = new List<Duty>();
    public ICollection<LeaveRequest> LeaveRequests { get; set; } = new List<LeaveRequest>();
    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    public ICollection<DutySwapRequest> SentSwapRequests { get; set; } = new List<DutySwapRequest>();
    public ICollection<DutySwapRequest> ReceivedSwapRequests { get; set; } = new List<DutySwapRequest>();
}
