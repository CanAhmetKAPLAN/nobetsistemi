using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NobetSistemi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddAdminVotes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AdminVotes",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    GroupId = table.Column<Guid>(type: "uuid", nullable: false),
                    CandidateUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    InitiatedById = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ResolvedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AdminVotes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AdminVotes_Groups_GroupId",
                        column: x => x.GroupId,
                        principalTable: "Groups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_AdminVotes_Users_CandidateUserId",
                        column: x => x.CandidateUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_AdminVotes_Users_InitiatedById",
                        column: x => x.InitiatedById,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "AdminVoteBallots",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    GroupId = table.Column<Guid>(type: "uuid", nullable: false),
                    AdminVoteId = table.Column<Guid>(type: "uuid", nullable: false),
                    VoterUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Approve = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AdminVoteBallots", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AdminVoteBallots_AdminVotes_AdminVoteId",
                        column: x => x.AdminVoteId,
                        principalTable: "AdminVotes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_AdminVoteBallots_Groups_GroupId",
                        column: x => x.GroupId,
                        principalTable: "Groups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_AdminVoteBallots_Users_VoterUserId",
                        column: x => x.VoterUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AdminVoteBallots_AdminVoteId_VoterUserId",
                table: "AdminVoteBallots",
                columns: new[] { "AdminVoteId", "VoterUserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_AdminVoteBallots_GroupId",
                table: "AdminVoteBallots",
                column: "GroupId");

            migrationBuilder.CreateIndex(
                name: "IX_AdminVoteBallots_VoterUserId",
                table: "AdminVoteBallots",
                column: "VoterUserId");

            migrationBuilder.CreateIndex(
                name: "IX_AdminVotes_CandidateUserId",
                table: "AdminVotes",
                column: "CandidateUserId");

            migrationBuilder.CreateIndex(
                name: "IX_AdminVotes_GroupId",
                table: "AdminVotes",
                column: "GroupId");

            migrationBuilder.CreateIndex(
                name: "IX_AdminVotes_InitiatedById",
                table: "AdminVotes",
                column: "InitiatedById");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AdminVoteBallots");

            migrationBuilder.DropTable(
                name: "AdminVotes");
        }
    }
}
