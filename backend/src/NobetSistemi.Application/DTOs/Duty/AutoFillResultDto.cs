namespace NobetSistemi.Application.DTOs.Duty;

public class AutoFillResultDto
{
    public int AssignedCount { get; set; }
    public int SkippedCount { get; set; }       // Uygun kullanıcı bulunamayan günler
    public int AlreadyFilledCount { get; set; }  // Zaten atanmış (manuel) günler
    public int UnchangedCount { get; set; }      // Yeniden hesaplandı ama kişi değişmedi
    public List<DutyDto> Duties { get; set; } = [];
}
