namespace NobetSistemi.Application.DTOs.Group;

public class GroupDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int MemberCount { get; set; }
    public string MyRole { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
