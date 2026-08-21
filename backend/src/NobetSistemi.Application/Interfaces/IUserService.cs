using NobetSistemi.Application.DTOs.User;

namespace NobetSistemi.Application.Interfaces;

public interface IUserService
{
    Task<UserDto> GetByIdAsync(Guid id);
    Task<UserDto> UpdateAsync(Guid id, UpdateUserDto dto);
}
