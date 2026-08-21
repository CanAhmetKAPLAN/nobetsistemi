using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.Infrastructure.BackgroundServices;

/// <summary>
/// Her ay başında (1. günü 00:01 UTC) tüm kullanıcıların TotalScore'unu
/// %20 azaltır. Bu sayede geçmiş ayların etkisi yavaşça sıfırlanır,
/// yeni kullanıcılar veya uzun süre nöbetsiz kalanlar dezavantajlı kalmaz.
/// </summary>
public class MonthEndDecayHostedService : BackgroundService
{
    private const double DecayFactor = 0.80;

    private readonly IServiceProvider _services;
    private readonly ILogger<MonthEndDecayHostedService> _logger;

    public MonthEndDecayHostedService(
        IServiceProvider services,
        ILogger<MonthEndDecayHostedService> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var delay = TimeUntilNextMonthStart();
            _logger.LogInformation(
                "Aylık decay servisi bir sonraki çalışma: {Next} ({Hours:F1} saat sonra)",
                DateTime.UtcNow.Add(delay), delay.TotalHours);

            try
            {
                await Task.Delay(delay, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            await ApplyDecayAsync();
        }
    }

    private async Task ApplyDecayAsync()
    {
        try
        {
            using var scope = _services.CreateScope();
            var membershipRepo = scope.ServiceProvider.GetRequiredService<IGroupMembershipRepository>();
            await membershipRepo.DecayAllScoresAsync(DecayFactor);
            _logger.LogInformation(
                "Aylık decay uygulandı: tüm grup üyeliklerinin puanları × {Factor} çarpıldı ({Month}/{Year})",
                DecayFactor,
                DateTime.UtcNow.Month,
                DateTime.UtcNow.Year);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Aylık decay uygulanırken hata oluştu");
        }
    }

    /// <summary>
    /// Bir sonraki ayın 1. günü 00:01 UTC'ye kadar olan süreyi döner.
    /// </summary>
    private static TimeSpan TimeUntilNextMonthStart()
    {
        var now = DateTime.UtcNow;
        var nextMonth = new DateTime(now.Year, now.Month, 1, 0, 1, 0, DateTimeKind.Utc)
            .AddMonths(1);
        var delay = nextMonth - now;
        return delay > TimeSpan.Zero ? delay : TimeSpan.FromMinutes(1);
    }
}
