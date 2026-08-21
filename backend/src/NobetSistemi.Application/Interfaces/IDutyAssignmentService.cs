using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Application.Interfaces;

public interface IDutyAssignmentService
{
    double GetDayWeight(DateTime date);
    Task<GroupMembership> SelectMemberForDateAsync(DateTime date);
    Task ValidateEligibilityAsync(Guid userId, DateTime date);
}
