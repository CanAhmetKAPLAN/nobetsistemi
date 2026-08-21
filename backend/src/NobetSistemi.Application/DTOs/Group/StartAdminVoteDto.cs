using System.ComponentModel.DataAnnotations;

namespace NobetSistemi.Application.DTOs.Group;

public class StartAdminVoteDto
{
    [Required]
    public Guid CandidateUserId { get; set; }
}
