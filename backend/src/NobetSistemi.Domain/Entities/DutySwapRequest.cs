using NobetSistemi.Domain.Enums;

namespace NobetSistemi.Domain.Entities;

public class DutySwapRequest
{
    public Guid Id { get; set; }
    public Guid GroupId { get; set; }
    public Group Group { get; set; } = null!;
    public Guid RequesterId { get; set; }
    public User Requester { get; set; } = null!;
    public Guid TargetUserId { get; set; }
    public User TargetUser { get; set; } = null!;
    public Guid RequesterDutyId { get; set; }
    public Duty RequesterDuty { get; set; } = null!;
    public Guid? TargetDutyId { get; set; }
    public Duty? TargetDuty { get; set; }
    public string Reason { get; set; } = string.Empty;
    public SwapStatus Status { get; set; } = SwapStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
