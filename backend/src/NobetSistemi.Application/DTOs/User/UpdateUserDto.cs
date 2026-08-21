using System.ComponentModel.DataAnnotations;

namespace NobetSistemi.Application.DTOs.User;

public class UpdateUserDto
{
    [MaxLength(100)]
    public string? Name { get; set; }
}
