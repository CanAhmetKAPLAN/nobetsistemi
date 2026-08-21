using NobetSistemi.Application.DTOs.Notification;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Exceptions;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.Application.Services;

public class NotificationService : INotificationService
{
    private readonly INotificationRepository _notificationRepository;
    private readonly ICurrentGroupContext _currentGroupContext;

    public NotificationService(
        INotificationRepository notificationRepository,
        ICurrentGroupContext currentGroupContext)
    {
        _notificationRepository = notificationRepository;
        _currentGroupContext = currentGroupContext;
    }

    public async Task<IEnumerable<NotificationDto>> GetByUserIdAsync(Guid userId)
    {
        var notifications = await _notificationRepository.GetByUserIdAsync(userId);
        return notifications.Select(MapToDto);
    }

    public async Task<int> GetUnreadCountAsync(Guid userId)
    {
        return await _notificationRepository.GetUnreadCountAsync(userId);
    }

    public async Task CreateAsync(Guid userId, string title, string message)
    {
        var notification = new Notification
        {
            Id = Guid.NewGuid(),
            GroupId = _currentGroupContext.GroupId,
            UserId = userId,
            Title = title,
            Message = message,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        await _notificationRepository.AddAsync(notification);
        await _notificationRepository.SaveChangesAsync();
    }

    public async Task MarkAsReadAsync(Guid id, Guid userId)
    {
        var notification = await _notificationRepository.GetByIdAsync(id)
            ?? throw new NotFoundException("Bildirim bulunamadı.");

        if (notification.UserId != userId)
            throw new UnauthorizedException("Bu bildirimi okuma yetkiniz yok.");

        notification.IsRead = true;
        _notificationRepository.Update(notification);
        await _notificationRepository.SaveChangesAsync();
    }

    public async Task MarkAllAsReadAsync(Guid userId)
    {
        await _notificationRepository.MarkAllAsReadAsync(userId);
    }

    private static NotificationDto MapToDto(Notification n) => new()
    {
        Id = n.Id,
        UserId = n.UserId,
        Title = n.Title,
        Message = n.Message,
        IsRead = n.IsRead,
        CreatedAt = n.CreatedAt
    };
}
