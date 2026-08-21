using System.ComponentModel.DataAnnotations;

namespace NobetSistemi.Application.DTOs.Swap;

public class CreateSwapRequestDto
{
    [Required]
    public Guid TargetUserId { get; set; }

    [Required]
    public Guid RequesterDutyId { get; set; }

    public Guid? TargetDutyId { get; set; }

    [MaxLength(500)]
    public string Reason { get; set; } = string.Empty;
}

public class ReviewSwapRequestDto
{
    [Required]
    public bool Approve { get; set; }
}
