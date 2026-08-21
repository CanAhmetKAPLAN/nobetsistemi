using System.ComponentModel.DataAnnotations;

namespace NobetSistemi.Application.DTOs.Duty;

public class CreateDutyDto
{
    [Required]
    public Guid UserId { get; set; }

    [Required]
    public DateTime Date { get; set; }

    public string? Notes { get; set; }
}

public class AutoAssignDutyDto
{
    [Required]
    public DateTime Date { get; set; }
}
