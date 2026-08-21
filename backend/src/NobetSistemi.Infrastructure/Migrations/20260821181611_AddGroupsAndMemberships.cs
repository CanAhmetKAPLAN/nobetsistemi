using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NobetSistemi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddGroupsAndMemberships : Migration
    {
        private const string DefaultGroupId = "00000000-0000-0000-0000-000000000001";

        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Groups",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    JoinCode = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    CreatedById = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Groups", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Groups_Users_CreatedById",
                        column: x => x.CreatedById,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "GroupMemberships",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    GroupId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Role = table.Column<int>(type: "integer", nullable: false),
                    Score = table.Column<double>(type: "double precision", nullable: false, defaultValue: 0.0),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    JoinedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GroupMemberships", x => x.Id);
                    table.ForeignKey(
                        name: "FK_GroupMemberships_Groups_GroupId",
                        column: x => x.GroupId,
                        principalTable: "Groups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_GroupMemberships_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            // ─── Mevcut veriyi "Varsayılan Grup"a taşı (canlı DB'de veri kaybı yok) ───
            // Users.Role/Score/IsActive kolonları bu noktada henüz silinmedi.
            migrationBuilder.Sql($@"
                INSERT INTO ""Groups"" (""Id"", ""Name"", ""JoinCode"", ""CreatedById"", ""CreatedAt"")
                SELECT '{DefaultGroupId}', 'Varsayılan Grup', 'VARSAYILAN',
                       (SELECT ""Id"" FROM ""Users"" ORDER BY ""CreatedAt"" LIMIT 1), now()
                WHERE EXISTS (SELECT 1 FROM ""Users"")
                  AND NOT EXISTS (SELECT 1 FROM ""Groups"" WHERE ""Id"" = '{DefaultGroupId}');

                INSERT INTO ""GroupMemberships"" (""Id"", ""GroupId"", ""UserId"", ""Role"", ""Score"", ""IsActive"", ""JoinedAt"")
                SELECT gen_random_uuid(), '{DefaultGroupId}', ""Id"", ""Role"", ""Score"", ""IsActive"", ""CreatedAt""
                FROM ""Users""
                WHERE EXISTS (SELECT 1 FROM ""Groups"" WHERE ""Id"" = '{DefaultGroupId}');
            ");

            migrationBuilder.AddColumn<Guid>(
                name: "GroupId",
                table: "Notifications",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "GroupId",
                table: "LeaveRequests",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid(DefaultGroupId));

            migrationBuilder.AddColumn<Guid>(
                name: "GroupId",
                table: "DutySwapRequests",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid(DefaultGroupId));

            migrationBuilder.AddColumn<Guid>(
                name: "GroupId",
                table: "Duties",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid(DefaultGroupId));

            migrationBuilder.DropIndex(
                name: "IX_Duties_UserId_Date",
                table: "Duties");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_GroupId",
                table: "Notifications",
                column: "GroupId");

            migrationBuilder.CreateIndex(
                name: "IX_LeaveRequests_GroupId",
                table: "LeaveRequests",
                column: "GroupId");

            migrationBuilder.CreateIndex(
                name: "IX_DutySwapRequests_GroupId",
                table: "DutySwapRequests",
                column: "GroupId");

            migrationBuilder.CreateIndex(
                name: "IX_Duties_GroupId_UserId_Date",
                table: "Duties",
                columns: new[] { "GroupId", "UserId", "Date" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Duties_UserId",
                table: "Duties",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_GroupMemberships_GroupId_UserId",
                table: "GroupMemberships",
                columns: new[] { "GroupId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_GroupMemberships_UserId",
                table: "GroupMemberships",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Groups_CreatedById",
                table: "Groups",
                column: "CreatedById");

            migrationBuilder.CreateIndex(
                name: "IX_Groups_JoinCode",
                table: "Groups",
                column: "JoinCode",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Duties_Groups_GroupId",
                table: "Duties",
                column: "GroupId",
                principalTable: "Groups",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_DutySwapRequests_Groups_GroupId",
                table: "DutySwapRequests",
                column: "GroupId",
                principalTable: "Groups",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_LeaveRequests_Groups_GroupId",
                table: "LeaveRequests",
                column: "GroupId",
                principalTable: "Groups",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Groups_GroupId",
                table: "Notifications",
                column: "GroupId",
                principalTable: "Groups",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            // Backfill tamamlandı — artık eski global Role/Score/IsActive kolonlarına gerek yok.
            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Role",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Score",
                table: "Users");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Duties_Groups_GroupId",
                table: "Duties");

            migrationBuilder.DropForeignKey(
                name: "FK_DutySwapRequests_Groups_GroupId",
                table: "DutySwapRequests");

            migrationBuilder.DropForeignKey(
                name: "FK_LeaveRequests_Groups_GroupId",
                table: "LeaveRequests");

            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Groups_GroupId",
                table: "Notifications");

            migrationBuilder.DropTable(
                name: "GroupMemberships");

            migrationBuilder.DropTable(
                name: "Groups");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_GroupId",
                table: "Notifications");

            migrationBuilder.DropIndex(
                name: "IX_LeaveRequests_GroupId",
                table: "LeaveRequests");

            migrationBuilder.DropIndex(
                name: "IX_DutySwapRequests_GroupId",
                table: "DutySwapRequests");

            migrationBuilder.DropIndex(
                name: "IX_Duties_GroupId_UserId_Date",
                table: "Duties");

            migrationBuilder.DropIndex(
                name: "IX_Duties_UserId",
                table: "Duties");

            migrationBuilder.DropColumn(
                name: "GroupId",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "GroupId",
                table: "LeaveRequests");

            migrationBuilder.DropColumn(
                name: "GroupId",
                table: "DutySwapRequests");

            migrationBuilder.DropColumn(
                name: "GroupId",
                table: "Duties");

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<int>(
                name: "Role",
                table: "Users",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<double>(
                name: "Score",
                table: "Users",
                type: "double precision",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.CreateIndex(
                name: "IX_Duties_UserId_Date",
                table: "Duties",
                columns: new[] { "UserId", "Date" },
                unique: true);
        }
    }
}
