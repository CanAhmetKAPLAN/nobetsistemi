using NobetSistemi.Application.DTOs.Duty;

namespace NobetSistemi.Application.Interfaces;

public interface IDutyService
{
    Task<IEnumerable<DutyDto>> GetAllAsync();
    Task<DutyDto> GetByIdAsync(Guid id);
    Task<IEnumerable<DutyDto>> GetByUserIdAsync(Guid userId);
    Task<IEnumerable<DutyDto>> GetByDateAsync(DateTime date);
    Task<IEnumerable<DutyDto>> GetByYearMonthAsync(int year, int month);
    Task<IEnumerable<MonthlyScoreDto>> GetMonthlyScoresAsync();
    Task<AutoFillResultDto> AutoFillMonthAsync(int year, int month);
    Task<AutoFillResultDto> RebalanceAsync(RebalanceDutiesDto dto);
    Task<DutyDto> CreateManualAsync(CreateDutyDto dto);
    Task<DutyDto> AutoAssignAsync(AutoAssignDutyDto dto);
    Task DeleteAsync(Guid id);
}
