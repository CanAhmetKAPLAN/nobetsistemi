using System.ComponentModel.DataAnnotations;

namespace NobetSistemi.Application.DTOs.Leave;

public class CreateLeaveRequestDto
{
    [Required]
    public DateTime StartDate { get; set; }

    [Required]
    public DateTime EndDate { get; set; }

    [MaxLength(500)]
    public string? Reason { get; set; }
}

public class ReviewLeaveRequestDto
{
    [Required]
    public bool Approve { get; set; }
}
