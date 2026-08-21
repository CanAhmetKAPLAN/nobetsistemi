using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Infrastructure.Data.Configurations;

public class AdminVoteConfiguration : IEntityTypeConfiguration<AdminVote>
{
    public void Configure(EntityTypeBuilder<AdminVote> builder)
    {
        builder.HasKey(v => v.Id);

        builder.HasOne(v => v.Group)
            .WithMany()
            .HasForeignKey(v => v.GroupId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(v => v.Candidate)
            .WithMany()
            .HasForeignKey(v => v.CandidateUserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(v => v.InitiatedBy)
            .WithMany()
            .HasForeignKey(v => v.InitiatedById)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
