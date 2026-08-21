using System.ComponentModel.DataAnnotations;

namespace NobetSistemi.Application.DTOs.Group;

public class CreateGroupDto
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MinLength(4)]
    [MaxLength(50)]
    public string JoinCode { get; set; } = string.Empty;
}
