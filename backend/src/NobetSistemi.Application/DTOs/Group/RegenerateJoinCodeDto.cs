using System.ComponentModel.DataAnnotations;

namespace NobetSistemi.Application.DTOs.Group;

public class RegenerateJoinCodeDto
{
    [Required]
    [MinLength(4)]
    [MaxLength(50)]
    public string NewJoinCode { get; set; } = string.Empty;
}

public class RegenerateJoinCodeResultDto
{
    public string JoinCode { get; set; } = string.Empty;
}
