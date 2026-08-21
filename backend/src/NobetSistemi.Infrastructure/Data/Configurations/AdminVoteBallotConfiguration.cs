using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Infrastructure.Data.Configurations;

public class AdminVoteBallotConfiguration : IEntityTypeConfiguration<AdminVoteBallot>
{
    public void Configure(EntityTypeBuilder<AdminVoteBallot> builder)
    {
        builder.HasKey(b => b.Id);
        builder.HasIndex(b => new { b.AdminVoteId, b.VoterUserId }).IsUnique();

        builder.HasOne(b => b.Group)
            .WithMany()
            .HasForeignKey(b => b.GroupId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(b => b.AdminVote)
            .WithMany(v => v.Ballots)
            .HasForeignKey(b => b.AdminVoteId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(b => b.Voter)
            .WithMany()
            .HasForeignKey(b => b.VoterUserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
