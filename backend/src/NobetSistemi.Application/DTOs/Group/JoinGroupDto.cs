using System.ComponentModel.DataAnnotations;

namespace NobetSistemi.Application.DTOs.Group;

public class JoinGroupDto
{
    [Required]
    public string JoinCode { get; set; } = string.Empty;
}
