using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NobetSistemi.Application.DTOs.Duty;
using NobetSistemi.Application.Interfaces;

namespace NobetSistemi.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DutiesController : ControllerBase
{
    private readonly IDutyService _dutyService;
    private readonly IAutoScheduleService _autoScheduleService;
    private readonly ICurrentGroupContext _currentGroupContext;

    public DutiesController(
        IDutyService dutyService,
        IAutoScheduleService autoScheduleService,
        ICurrentGroupContext currentGroupContext)
    {
        _dutyService = dutyService;
        _autoScheduleService = autoScheduleService;
        _currentGroupContext = currentGroupContext;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<DutyDto>>> GetAll()
    {
        var duties = await _dutyService.GetAllAsync();
        return Ok(duties);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<DutyDto>> GetById(Guid id)
    {
        var duty = await _dutyService.GetByIdAsync(id);
        return Ok(duty);
    }

    [HttpGet("by-date")]
    public async Task<ActionResult<IEnumerable<DutyDto>>> GetByDate([FromQuery] DateTime date)
    {
        var duties = await _dutyService.GetByDateAsync(date);
        return Ok(duties);
    }

    [HttpGet("by-user/{userId:guid}")]
    public async Task<ActionResult<IEnumerable<DutyDto>>> GetByUser(Guid userId)
    {
        var duties = await _dutyService.GetByUserIdAsync(userId);
        return Ok(duties);
    }

    [HttpGet("by-month")]
    public async Task<ActionResult<IEnumerable<DutyDto>>> GetByMonth([FromQuery] int year, [FromQuery] int month)
    {
        var duties = await _dutyService.GetByYearMonthAsync(year, month);
        return Ok(duties);
    }

    [HttpGet("monthly-scores")]
    public async Task<ActionResult<IEnumerable<MonthlyScoreDto>>> GetMonthlyScores()
    {
        var scores = await _dutyService.GetMonthlyScoresAsync();
        return Ok(scores);
    }

    [HttpPost("manual")]
    public async Task<ActionResult<DutyDto>> CreateManual([FromBody] CreateDutyDto dto)
    {
        var duty = await _dutyService.CreateManualAsync(dto);

        // Grup ilk açıldığında otomasyon, admin ilk nöbeti kendisi atayana
        // kadar beklemede kalır — bu ilk manuel atamayla tetiklenir.
        try
        {
            var groupId = _currentGroupContext.RequireGroupId();
            await _autoScheduleService.EnsureInitialScheduleAsync(groupId);
        }
        catch
        {
            // Otomatik planlama başarısız olsa bile manuel atama geçerli kalsın.
        }

        return CreatedAtAction(nameof(GetById), new { id = duty.Id }, duty);
    }

    [HttpPost("auto-assign")]
    public async Task<ActionResult<DutyDto>> AutoAssign([FromBody] AutoAssignDutyDto dto)
    {
        var duty = await _dutyService.AutoAssignAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = duty.Id }, duty);
    }

    [HttpPost("auto-fill-month")]
    public async Task<ActionResult<AutoFillResultDto>> AutoFillMonth([FromBody] AutoFillMonthRequestDto dto)
    {
        var result = await _dutyService.AutoFillMonthAsync(dto.Year, dto.Month);
        return Ok(result);
    }

    [HttpPost("rebalance")]
    public async Task<ActionResult<AutoFillResultDto>> Rebalance([FromBody] RebalanceDutiesDto dto)
    {
        var result = await _dutyService.RebalanceAsync(dto);
        return Ok(result);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _dutyService.DeleteAsync(id);
        return NoContent();
    }
}
