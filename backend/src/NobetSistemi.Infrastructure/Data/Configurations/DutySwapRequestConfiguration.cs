using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Infrastructure.Data.Configurations;

public class DutySwapRequestConfiguration : IEntityTypeConfiguration<DutySwapRequest>
{
    public void Configure(EntityTypeBuilder<DutySwapRequest> builder)
    {
        builder.HasKey(s => s.Id);
        builder.Property(s => s.Reason).HasMaxLength(500);

        builder.HasOne(s => s.Group)
            .WithMany()
            .HasForeignKey(s => s.GroupId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(s => s.Requester)
            .WithMany(u => u.SentSwapRequests)
            .HasForeignKey(s => s.RequesterId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(s => s.TargetUser)
            .WithMany(u => u.ReceivedSwapRequests)
            .HasForeignKey(s => s.TargetUserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(s => s.RequesterDuty)
            .WithMany()
            .HasForeignKey(s => s.RequesterDutyId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(s => s.TargetDuty)
            .WithMany()
            .HasForeignKey(s => s.TargetDutyId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
