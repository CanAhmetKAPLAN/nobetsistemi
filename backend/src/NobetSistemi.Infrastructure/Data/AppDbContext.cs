using Microsoft.EntityFrameworkCore;
using NobetSistemi.Application.Interfaces;
using NobetSistemi.Domain.Entities;

namespace NobetSistemi.Infrastructure.Data;

public class AppDbContext : DbContext
{
    private readonly ICurrentGroupContext _currentGroupContext;

    public AppDbContext(DbContextOptions<AppDbContext> options, ICurrentGroupContext currentGroupContext)
        : base(options)
    {
        _currentGroupContext = currentGroupContext;
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Group> Groups => Set<Group>();
    public DbSet<GroupMembership> GroupMemberships => Set<GroupMembership>();
    public DbSet<Duty> Duties => Set<Duty>();
    public DbSet<LeaveRequest> LeaveRequests => Set<LeaveRequest>();
    public DbSet<DutySwapRequest> DutySwapRequests => Set<DutySwapRequest>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<AdminVote> AdminVotes => Set<AdminVote>();
    public DbSet<AdminVoteBallot> AdminVoteBallots => Set<AdminVoteBallot>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);

        // Çok kiracılı izolasyon: her istek yalnızca X-Group-Id header'ı ile
        // doğrulanmış aktif grubun verisini görür. GroupMembership, AdminVote ve
        // AdminVoteBallot kasıtlı olarak filtrelenmez — bunlar GroupsController
        // üzerinden, X-Group-Id header'ı olmadan, açık groupId route parametresi +
        // servis katmanında açık üyelik kontrolüyle erişilir (GroupService'teki
        // RequireGroupAdminAsync gibi) — grup seçilmeden önce de çalışabilmeliler.
        modelBuilder.Entity<Duty>().HasQueryFilter(d => d.GroupId == _currentGroupContext.GroupId);
        modelBuilder.Entity<LeaveRequest>().HasQueryFilter(l => l.GroupId == _currentGroupContext.GroupId);
        modelBuilder.Entity<DutySwapRequest>().HasQueryFilter(s => s.GroupId == _currentGroupContext.GroupId);
        modelBuilder.Entity<Notification>().HasQueryFilter(n => n.GroupId == null || n.GroupId == _currentGroupContext.GroupId);
    }
}
