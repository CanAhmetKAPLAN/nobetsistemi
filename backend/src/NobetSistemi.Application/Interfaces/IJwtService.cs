using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Application.Interfaces;

public interface IJwtService
{
    string GenerateToken(User user);
}
