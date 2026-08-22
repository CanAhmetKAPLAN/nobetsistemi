using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.Infrastructure.BackgroundServices;

/// <summary>
/// Her gün tüm grupları tarayıp, en az 3 aktif üyesi olanların nöbet
/// takvimini "bu ay + gelecek ay" penceresinde eksiksiz tutar. Zaman
/// ilerleyip yeni bir ay ufka girdiğinde bu servis onu otomatik doldurur.
/// Uygulama başlar başlamaz da bir kez çalışır (yeni deploy/restart sonrası
/// beklemeden güncel kalsın diye).
/// </summary>
public class AutoScheduleHostedService : BackgroundService
{
    private readonly IServiceProvider _services;
    private readonly ILogger<AutoScheduleHostedService> _logger;

    public AutoScheduleHostedService(IServiceProvider services, ILogger<AutoScheduleHostedService> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await ExtendAllGroupsAsync();

            try
            {
                await Task.Delay(TimeSpan.FromHours(24), stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
        }
    }

    private async Task ExtendAllGroupsAsync()
    {
        List<Guid> groupIds;
        try
        {
            using var listScope = _services.CreateScope();
            var groupRepo = listScope.ServiceProvider.GetRequiredService<IGroupRepository>();
            groupIds = (await groupRepo.GetAllAsync()).Select(g => g.Id).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Otomatik nöbet planlama servisi grup listesi alınamadı");
            return;
        }

        foreach (var groupId in groupIds)
        {
            try
            {
                using var scope = _services.CreateScope();
                var scheduleService = scope.ServiceProvider.GetRequiredService<IAutoScheduleService>();
                await scheduleService.ExtendRollingScheduleAsync(groupId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Grup {GroupId} için otomatik nöbet planlaması başarısız", groupId);
            }
        }

        _logger.LogInformation("Otomatik nöbet planlaması tamamlandı: {Count} grup kontrol edildi", groupIds.Count);
    }
}
