using Microsoft.EntityFrameworkCore;
using NobetSistemi.Domain.Entities;
using NobetSistemi.Domain.Enums;
using NobetSistemi.Infrastructure.Data;

namespace NobetSistemi.Infrastructure.Seed;

public static class DataSeeder
{
    /// <summary>
    /// Migration'daki "Varsayılan Grup" backfill'iyle aynı sabit GUID —
    /// gerçek bir DB'de bu id migration tarafından kullanılır, tamamen boş
    /// bir DB'de ise burada (seed) oluşturulur. İkisi asla aynı anda çakışmaz
    /// çünkü migration backfill'i yalnızca Users tablosu doluysa çalışır.
    /// </summary>
    public static readonly Guid DefaultGroupId = Guid.Parse("00000000-0000-0000-0000-000000000001");

    public static async Task SeedAsync(AppDbContext context)
    {
        if (await context.Users.AnyAsync()) return;

        var adminId = Guid.NewGuid();
        var users = new List<(User User, GroupRole Role, double Score)>
        {
            (new User
            {
                Id = adminId,
                Name = "Admin Yönetici",
                Email = "admin@nobet.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin123!"),
                CreatedAt = DateTime.UtcNow
            }, GroupRole.Admin, 0),
            (new User
            {
                Id = Guid.NewGuid(),
                Name = "Ahmet Yılmaz",
                Email = "ahmet@nobet.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("User123!"),
                CreatedAt = DateTime.UtcNow
            }, GroupRole.Member, 3),
            (new User
            {
                Id = Guid.NewGuid(),
                Name = "Fatma Kaya",
                Email = "fatma@nobet.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("User123!"),
                CreatedAt = DateTime.UtcNow
            }, GroupRole.Member, 5),
            (new User
            {
                Id = Guid.NewGuid(),
                Name = "Mehmet Demir",
                Email = "mehmet@nobet.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("User123!"),
                CreatedAt = DateTime.UtcNow
            }, GroupRole.Member, 2),
            (new User
            {
                Id = Guid.NewGuid(),
                Name = "Ayşe Çelik",
                Email = "ayse@nobet.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("User123!"),
                CreatedAt = DateTime.UtcNow
            }, GroupRole.Member, 2),
            (new User
            {
                Id = Guid.NewGuid(),
                Name = "Ali Şahin",
                Email = "ali@nobet.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("User123!"),
                CreatedAt = DateTime.UtcNow
            }, GroupRole.Member, 4)
        };

        await context.Users.AddRangeAsync(users.Select(u => u.User));
        await context.SaveChangesAsync();

        var group = new Group
        {
            Id = DefaultGroupId,
            Name = "Varsayılan Grup",
            JoinCode = "VARSAYILAN",
            CreatedById = adminId,
            CreatedAt = DateTime.UtcNow
        };
        await context.Groups.AddAsync(group);
        await context.SaveChangesAsync();

        var memberships = users.Select(u => new GroupMembership
        {
            Id = Guid.NewGuid(),
            GroupId = group.Id,
            UserId = u.User.Id,
            Role = u.Role,
            Score = u.Score,
            IsActive = true,
            JoinedAt = DateTime.UtcNow
        });
        await context.GroupMemberships.AddRangeAsync(memberships);
        await context.SaveChangesAsync();

        // Geçmiş nöbetler
        var today = DateTime.UtcNow.Date;
        var duties = new List<Duty>();
        var nonAdminUsers = users.Skip(1).Select(u => u.User).ToList();

        for (int i = -6; i <= -1; i++)
        {
            var date = today.AddDays(i);
            var userIndex = ((i + 6) % nonAdminUsers.Count);
            var user = nonAdminUsers[userIndex];

            duties.Add(new Duty
            {
                Id = Guid.NewGuid(),
                GroupId = group.Id,
                UserId = user.Id,
                Date = date,
                IsAutoAssigned = true,
                CreatedAt = DateTime.UtcNow
            });
        }

        await context.Duties.AddRangeAsync(duties);
        await context.SaveChangesAsync();
    }
}
