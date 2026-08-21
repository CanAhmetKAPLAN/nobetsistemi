using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Application.Services;
using NobetSistemi.Domain.Interfaces;
using NobetSistemi.Infrastructure.BackgroundServices;
using NobetSistemi.Infrastructure.Data;
using NobetSistemi.Infrastructure.Repositories;
using NobetSistemi.Infrastructure.Services;

namespace NobetSistemi.Infrastructure.Extensions;

public static class InfrastructureServiceExtensions
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(configuration.GetConnectionString("DefaultConnection")));

        // Repositories
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IGroupRepository, GroupRepository>();
        services.AddScoped<IGroupMembershipRepository, GroupMembershipRepository>();
        services.AddScoped<IDutyRepository, DutyRepository>();
        services.AddScoped<ILeaveRequestRepository, LeaveRequestRepository>();
        services.AddScoped<IDutySwapRequestRepository, DutySwapRequestRepository>();
        services.AddScoped<INotificationRepository, NotificationRepository>();
        services.AddScoped<IAdminVoteRepository, AdminVoteRepository>();

        // Services
        services.AddScoped<ICurrentGroupContext, CurrentGroupContext>();
        services.AddScoped<IJwtService, JwtService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IGroupService, GroupService>();
        services.AddScoped<IAdminVoteService, AdminVoteService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<IDutyService, DutyService>();
        services.AddScoped<ILeaveService, LeaveService>();
        services.AddScoped<ISwapService, SwapService>();
        services.AddScoped<IDutyAssignmentService, DutyAssignmentService>();

        // FCM
        InitFirebase(configuration);
        services.AddScoped<IFcmNotificationService, FcmNotificationService>();
        services.AddHostedService<DutyReminderHostedService>();
        services.AddHostedService<MonthEndDecayHostedService>();

        return services;
    }

    private static void InitFirebase(IConfiguration configuration)
    {
        if (FirebaseApp.DefaultInstance != null) return;

        // Production'da (ör. Railway) servis hesabı bir dosya olarak deploy
        // edilmiyor — bunun yerine tüm JSON içeriği Firebase__ServiceAccountJson
        // ortam değişkeninde tutulur. Yerel geliştirmede ise dosya yolu (
        // Firebase:ServiceAccountPath) kullanılmaya devam eder.
        var credentialJson = configuration["Firebase:ServiceAccountJson"];
        var credentialPath = configuration["Firebase:ServiceAccountPath"];
        GoogleCredential credential;

        if (!string.IsNullOrWhiteSpace(credentialJson))
        {
            credential = GoogleCredential.FromJson(credentialJson);
        }
        else if (!string.IsNullOrEmpty(credentialPath) && File.Exists(credentialPath))
        {
            credential = GoogleCredential.FromFile(credentialPath);
        }
        else
        {
            // Uygulama çalışırken Firebase devre dışı — SendAsync sessizce başarısız olur
            return;
        }

        FirebaseApp.Create(new AppOptions { Credential = credential });
    }
}
