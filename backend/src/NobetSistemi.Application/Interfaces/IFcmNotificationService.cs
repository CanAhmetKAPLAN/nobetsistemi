namespace NobetSistemi.Application.Interfaces;

public interface IFcmNotificationService
{
    Task SendAsync(string fcmToken, string title, string body, string type);
    Task SendToUserAsync(Guid userId, string title, string body, string type);
}
