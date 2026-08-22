namespace NobetSistemi.Application.Interfaces;

public interface IAutoScheduleService
{
    /// <summary>
    /// Bir üye gruba katılıp aktif üye sayısı eşiği (3) sağlandığında/korunduğunda
    /// çağrılır — bugünden gelecek ayın sonuna kadar olan nöbetleri güncel üye
    /// listesiyle (yeni katılan dahil) hemen yeniden dağıtır.
    /// </summary>
    Task EnsureInitialScheduleAsync(Guid groupId);

    /// <summary>
    /// Günlük arka plan servisi tarafından çağrılır — yakın birkaç günü sabit
    /// bırakıp geri kalan pencereyi (bugünden gelecek ayın sonuna kadar) güncel
    /// puanlarla yeniden dengeler. Bu sayede yeni katılan birinin ya da
    /// izin/manuel değişiklik sonrası açılan puan farkının kendini zamanla
    /// düzeltmesini sağlar — tek seferlik ilk plana sıkışıp kalmaz.
    /// </summary>
    Task RefreshScheduleAsync(Guid groupId);
}
