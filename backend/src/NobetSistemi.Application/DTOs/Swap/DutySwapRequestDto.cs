namespace NobetSistemi.Application.DTOs.Swap;

public class DutySwapRequestDto
{
    public Guid Id { get; set; }
    public Guid RequesterId { get; set; }
    public string RequesterName { get; set; } = string.Empty;
    public Guid TargetUserId { get; set; }
    public string TargetUserName { get; set; } = string.Empty;
    public Guid RequesterDutyId { get; set; }
    public DateTime RequesterDutyDate { get; set; }
    public Guid? TargetDutyId { get; set; }
    public DateTime? TargetDutyDate { get; set; }
    public string Reason { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
