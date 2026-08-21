using FirebaseAdmin.Messaging;
using Microsoft.Extensions.Logging;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.Infrastructure.Services;

public class FcmNotificationService : IFcmNotificationService
{
    private readonly IUserRepository _userRepository;
    private readonly ILogger<FcmNotificationService> _logger;

    public FcmNotificationService(IUserRepository userRepository, ILogger<FcmNotificationService> logger)
    {
        _userRepository = userRepository;
        _logger = logger;
    }

    public async Task SendAsync(string fcmToken, string title, string body, string type)
    {
        try
        {
            var message = new Message
            {
                Token = fcmToken,
                Notification = new Notification { Title = title, Body = body },
                Data = new Dictionary<string, string> { ["type"] = type },
                Android = new AndroidConfig
                {
                    Priority = Priority.High,
                    Notification = new AndroidNotification { ChannelId = "nobet_default" }
                },
                Apns = new ApnsConfig
                {
                    Aps = new Aps { Badge = 1, Sound = "default" }
                }
            };

            var response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
            _logger.LogDebug("FCM gönderildi: {MessageId}", response);
        }
        catch (Exception ex)
        {
            _logger.LogWarning("FCM gönderilemedi: {Error}", ex.Message);
        }
    }

    public async Task SendToUserAsync(Guid userId, string title, string body, string type)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user?.FcmToken is null) return;
        await SendAsync(user.FcmToken, title, body, type);
    }
}
