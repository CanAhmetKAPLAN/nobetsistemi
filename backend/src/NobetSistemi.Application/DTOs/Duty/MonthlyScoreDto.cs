namespace NobetSistemi.Application.DTOs.Duty;

public class MonthlyScoreDto
{
    public Guid UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public int Year { get; set; }
    public int Month { get; set; }
    public int Score { get; set; }
}
