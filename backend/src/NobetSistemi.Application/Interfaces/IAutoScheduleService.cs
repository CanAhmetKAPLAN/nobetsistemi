namespace NobetSistemi.Application.Interfaces;

public interface IAutoScheduleService
{
    /// <summary>
    /// Bir üye gruba katılıp aktif üye sayısı eşiği (3) sağlandığında/korunduğunda
    /// çağrılır — bugünden gelecek ayın sonuna kadar olan nöbetleri güncel üye
    /// listesiyle (yeni katılan dahil) yeniden dağıtır.
    /// </summary>
    Task EnsureInitialScheduleAsync(Guid groupId);

    /// <summary>
    /// Periyodik arka plan servisi tarafından çağrılır — bu ay ve gelecek ayda
    /// eksik (henüz atanmamış) günleri doldurur. Var olan atamalara dokunmaz.
    /// </summary>
    Task ExtendRollingScheduleAsync(Guid groupId);
}
