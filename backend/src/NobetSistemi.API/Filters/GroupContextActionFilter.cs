using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Interfaces;

namespace NobetSistemi.API.Filters;

/// <summary>
/// İstekte "X-Group-Id" header'ı varsa, kullanıcının o gruba aktif üyeliğini
/// tek sorguyla doğrulayıp ICurrentGroupContext'i doldurur. Header yoksa
/// hiçbir şey yapmaz (grup gerektiren endpoint'ler ICurrentGroupContext
/// .RequireGroupId() ile kendi hatasını fırlatır). Header VARSA ama üyelik
/// geçersizse istek 403 ile reddedilir (fail-closed).
/// </summary>
public class GroupContextActionFilter : IAsyncActionFilter
{
    public const string GroupHeaderName = "X-Group-Id";

    private readonly IGroupMembershipRepository _membershipRepository;
    private readonly ICurrentGroupContext _currentGroupContext;

    public GroupContextActionFilter(
        IGroupMembershipRepository membershipRepository,
        ICurrentGroupContext currentGroupContext)
    {
        _membershipRepository = membershipRepository;
        _currentGroupContext = currentGroupContext;
    }

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var httpContext = context.HttpContext;

        if (httpContext.User.Identity?.IsAuthenticated == true &&
            httpContext.Request.Headers.TryGetValue(GroupHeaderName, out var groupIdHeader) &&
            Guid.TryParse(groupIdHeader, out var groupId))
        {
            var userIdClaim = httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim is null || !Guid.TryParse(userIdClaim, out var userId))
            {
                context.Result = Problem(403, "Geçersiz kullanıcı kimliği.");
                return;
            }

            var membership = await _membershipRepository.GetAsync(groupId, userId);
            if (membership is null || !membership.IsActive)
            {
                context.Result = Problem(403, "Bu gruba üye değilsiniz.");
                return;
            }

            _currentGroupContext.SetGroup(groupId, membership.Role);
        }

        await next();
    }

    private static ObjectResult Problem(int statusCode, string message) => new(new
    {
        statusCode,
        message,
        timestamp = DateTime.UtcNow
    })
    { StatusCode = statusCode };
}
