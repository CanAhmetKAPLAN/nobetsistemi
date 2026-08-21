namespace NobetSistemi.Domain.Entities;

public class Notification
{
    public Guid Id { get; set; }
    public Guid? GroupId { get; set; }
    public Group? Group { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
