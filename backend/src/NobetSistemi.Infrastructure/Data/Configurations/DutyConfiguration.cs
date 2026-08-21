using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Infrastructure.Data.Configurations;

public class DutyConfiguration : IEntityTypeConfiguration<Duty>
{
    public void Configure(EntityTypeBuilder<Duty> builder)
    {
        builder.HasKey(d => d.Id);
        builder.Property(d => d.Date).IsRequired();
        builder.HasIndex(d => new { d.GroupId, d.UserId, d.Date }).IsUnique();

        builder.HasOne(d => d.Group)
            .WithMany()
            .HasForeignKey(d => d.GroupId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(d => d.User)
            .WithMany(u => u.Duties)
            .HasForeignKey(d => d.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
