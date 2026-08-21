using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NobetSistemi.Application.DTOs.Group;
using NobetSistemi.Application.Interfaces;

namespace NobetSistemi.API.Controllers;

[ApiController]
[Route("api/groups")]
[Authorize]
public class GroupsController : ControllerBase
{
    private readonly IGroupService _groupService;
    private readonly IAdminVoteService _adminVoteService;

    public GroupsController(IGroupService groupService, IAdminVoteService adminVoteService)
    {
        _groupService = groupService;
        _adminVoteService = adminVoteService;
    }

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpPost]
    public async Task<ActionResult<GroupDto>> Create([FromBody] CreateGroupDto dto)
    {
        var group = await _groupService.CreateAsync(CurrentUserId, dto);
        return CreatedAtAction(nameof(GetById), new { id = group.Id }, group);
    }

    [HttpPost("join")]
    public async Task<ActionResult<GroupDto>> Join([FromBody] JoinGroupDto dto)
    {
        var group = await _groupService.JoinAsync(CurrentUserId, dto);
        return Ok(group);
    }

    [HttpGet("mine")]
    public async Task<ActionResult<IEnumerable<GroupDto>>> GetMine()
    {
        var groups = await _groupService.GetMyGroupsAsync(CurrentUserId);
        return Ok(groups);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<GroupDto>> GetById(Guid id)
    {
        var group = await _groupService.GetByIdAsync(id, CurrentUserId);
        return Ok(group);
    }

    [HttpGet("{id:guid}/members")]
    public async Task<ActionResult<IEnumerable<GroupMembershipDto>>> GetMembers(Guid id)
    {
        var members = await _groupService.GetMembersAsync(id, CurrentUserId);
        return Ok(members);
    }

    [HttpPost("{id:guid}/regenerate-code")]
    public async Task<ActionResult<RegenerateJoinCodeResultDto>> RegenerateCode(Guid id, [FromBody] RegenerateJoinCodeDto dto)
    {
        var code = await _groupService.RegenerateJoinCodeAsync(id, CurrentUserId, dto.NewJoinCode);
        return Ok(new RegenerateJoinCodeResultDto { JoinCode = code });
    }

    [HttpPut("{id:guid}/members/{userId:guid}")]
    public async Task<IActionResult> UpdateMember(Guid id, Guid userId, [FromBody] UpdateMembershipDto dto)
    {
        await _groupService.UpdateMemberAsync(id, CurrentUserId, userId, dto);
        return NoContent();
    }

    [HttpDelete("{id:guid}/members/{userId:guid}")]
    public async Task<IActionResult> RemoveMember(Guid id, Guid userId)
    {
        await _groupService.RemoveMemberAsync(id, CurrentUserId, userId);
        return NoContent();
    }

    [HttpPost("{id:guid}/admin-vote")]
    public async Task<ActionResult<AdminVoteDto>> StartAdminVote(Guid id, [FromBody] StartAdminVoteDto dto)
    {
        var vote = await _adminVoteService.StartAsync(id, CurrentUserId, dto);
        return CreatedAtAction(nameof(GetActiveAdminVote), new { id }, vote);
    }

    [HttpGet("{id:guid}/admin-vote")]
    public async Task<ActionResult<AdminVoteDto>> GetActiveAdminVote(Guid id)
    {
        var vote = await _adminVoteService.GetActiveAsync(id, CurrentUserId);
        if (vote is null) return NoContent();
        return Ok(vote);
    }

    [HttpPut("{id:guid}/admin-vote/{voteId:guid}/cast")]
    public async Task<ActionResult<AdminVoteDto>> CastAdminVote(Guid id, Guid voteId, [FromBody] CastVoteDto dto)
    {
        var vote = await _adminVoteService.CastVoteAsync(id, voteId, CurrentUserId, dto);
        return Ok(vote);
    }

    [HttpDelete("{id:guid}/admin-vote/{voteId:guid}")]
    public async Task<IActionResult> CancelAdminVote(Guid id, Guid voteId)
    {
        await _adminVoteService.CancelAsync(id, voteId, CurrentUserId);
        return NoContent();
    }
}
