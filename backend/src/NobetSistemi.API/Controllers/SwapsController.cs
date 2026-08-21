using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NobetSistemi.Application.DTOs.Swap;
using NobetSistemi.Application.Interfaces;

namespace NobetSistemi.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SwapsController : ControllerBase
{
    private readonly ISwapService _swapService;

    public SwapsController(ISwapService swapService)
    {
        _swapService = swapService;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<DutySwapRequestDto>>> GetAll()
    {
        var swaps = await _swapService.GetAllAsync();
        return Ok(swaps);
    }

    [HttpGet("pending")]
    public async Task<ActionResult<IEnumerable<DutySwapRequestDto>>> GetPending()
    {
        var swaps = await _swapService.GetPendingAsync();
        return Ok(swaps);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<DutySwapRequestDto>> GetById(Guid id)
    {
        var swap = await _swapService.GetByIdAsync(id);
        return Ok(swap);
    }

    [HttpGet("my")]
    public async Task<ActionResult<IEnumerable<DutySwapRequestDto>>> GetMy()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var swaps = await _swapService.GetByRequesterIdAsync(userId);
        return Ok(swaps);
    }

    [HttpPost]
    public async Task<ActionResult<DutySwapRequestDto>> Create([FromBody] CreateSwapRequestDto dto)
    {
        var requesterId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var swap = await _swapService.CreateAsync(requesterId, dto);
        return CreatedAtAction(nameof(GetById), new { id = swap.Id }, swap);
    }

    [HttpPut("{id:guid}/review")]
    public async Task<ActionResult<DutySwapRequestDto>> Review(Guid id, [FromBody] ReviewSwapRequestDto dto)
    {
        var reviewerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var swap = await _swapService.ReviewAsync(id, reviewerId, dto);
        return Ok(swap);
    }

    [HttpPut("{id:guid}/cancel")]
    public async Task<IActionResult> Cancel(Guid id)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        await _swapService.CancelAsync(id, userId);
        return NoContent();
    }
}
