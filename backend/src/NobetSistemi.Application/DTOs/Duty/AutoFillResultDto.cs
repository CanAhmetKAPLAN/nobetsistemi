namespace NobetSistemi.Application.DTOs.Duty;

public class AutoFillResultDto
{
    public int AssignedCount { get; set; }
    public int SkippedCount { get; set; }       // Uygun kullanıcı bulunamayan günler
    public int AlreadyFilledCount { get; set; }  // Zaten atanmış günler
    public List<DutyDto> Duties { get; set; } = [];
}
