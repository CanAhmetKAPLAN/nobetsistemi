namespace NobetSistemi.Application.DTOs.Duty;

public class DutyDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public bool IsAutoAssigned { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
}
