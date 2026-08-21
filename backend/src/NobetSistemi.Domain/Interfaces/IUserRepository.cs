using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Domain.Interfaces;

public interface IUserRepository : IRepository<User>
{
    Task<User?> GetByEmailAsync(string email);
    Task<bool> EmailExistsAsync(string email);
    Task UpdateFcmTokenAsync(Guid userId, string fcmToken);
}
