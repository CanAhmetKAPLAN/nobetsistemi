using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.Infrastructure.BackgroundServices;

public class DutyReminderHostedService : BackgroundService
{
    private readonly IServiceProvider _services;
    private readonly ILogger<DutyReminderHostedService> _logger;

    public DutyReminderHostedService(IServiceProvider services, ILogger<DutyReminderHostedService> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var now = DateTime.UtcNow;
            // Her gün 06:00 UTC'de çalış (Türkiye saatiyle 09:00)
            var nextRun = now.Date.AddDays(now.Hour >= 6 ? 1 : 0).AddHours(6);
            var delay = nextRun - now;

            _logger.LogInformation("Nöbet hatırlatma servisi bir sonraki çalışma: {NextRun}", nextRun);

            try
            {
                await Task.Delay(delay, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            await SendRemindersAsync(stoppingToken);
        }
    }

    private async Task SendRemindersAsync(CancellationToken ct)
    {
        try
        {
            using var scope = _services.CreateScope();
            var dutyRepo = scope.ServiceProvider.GetRequiredService<IDutyRepository>();
            var fcm = scope.ServiceProvider.GetRequiredService<IFcmNotificationService>();

            var today = DateTime.UtcNow.Date;
            var tomorrow = today.AddDays(1);

            // Yarınki nöbetler için hatırlatma (1 gün önce, saat 09:00 Türkiye = 06:00 UTC)
            var tomorrowDuties = await dutyRepo.GetAllDutiesOnDateIgnoringGroupAsync(tomorrow);
            foreach (var duty in tomorrowDuties)
            {
                await fcm.SendToUserAsync(duty.UserId,
                    "⏰ Nöbet Hatırlatması",
                    $"Yarın ({tomorrow:dd/MM/yyyy}) nöbetiniz var.",
                    "duty_reminder");
            }

            // Bugünkü nöbet bildirimi (saat 07:00 Türkiye = 04:00 UTC)
            // Bu ayrı bir zamanlama gerektiriyor; basitleştirmek için aynı turda gönder
            var todayDuties = await dutyRepo.GetAllDutiesOnDateIgnoringGroupAsync(today);
            foreach (var duty in todayDuties)
            {
                await fcm.SendToUserAsync(duty.UserId,
                    "🏥 Bugün Nöbetsiniz!",
                    $"Bugün ({today:dd/MM/yyyy}) nöbetiniz var.",
                    "duty_today");
            }

            _logger.LogInformation("Nöbet hatırlatmaları gönderildi. Yarın: {Tomorrow}, Bugün: {Today}",
                tomorrowDuties.Count(), todayDuties.Count());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Nöbet hatırlatma servisi hatası");
        }
    }
}
