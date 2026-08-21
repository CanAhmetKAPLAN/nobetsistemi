using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NobetSistemi.Application.DTOs.Leave;
using NobetSistemi.Application.Interfaces;

namespace NobetSistemi.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class LeavesController : ControllerBase
{
    private readonly ILeaveService _leaveService;

    public LeavesController(ILeaveService leaveService)
    {
        _leaveService = leaveService;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<LeaveRequestDto>>> GetAll()
    {
        var leaves = await _leaveService.GetAllAsync();
        return Ok(leaves);
    }

    [HttpGet("pending")]
    public async Task<ActionResult<IEnumerable<LeaveRequestDto>>> GetPending()
    {
        var leaves = await _leaveService.GetPendingAsync();
        return Ok(leaves);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<LeaveRequestDto>> GetById(Guid id)
    {
        var leave = await _leaveService.GetByIdAsync(id);
        return Ok(leave);
    }

    [HttpGet("my")]
    public async Task<ActionResult<IEnumerable<LeaveRequestDto>>> GetMy()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var leaves = await _leaveService.GetByUserIdAsync(userId);
        return Ok(leaves);
    }

    [HttpPost]
    public async Task<ActionResult<LeaveRequestDto>> Create([FromBody] CreateLeaveRequestDto dto)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var leave = await _leaveService.CreateAsync(userId, dto);
        return CreatedAtAction(nameof(GetById), new { id = leave.Id }, leave);
    }

    [HttpPut("{id:guid}/review")]
    public async Task<ActionResult<LeaveRequestDto>> Review(Guid id, [FromBody] ReviewLeaveRequestDto dto)
    {
        var reviewerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var leave = await _leaveService.ReviewAsync(id, reviewerId, dto);
        return Ok(leave);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _leaveService.DeleteAsync(id);
        return NoContent();
    }
}
