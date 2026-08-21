using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NobetSistemi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class FixMissingFcmTokenColumn : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Önceki "AddFcmToken" migration'ının Designer.cs dosyası eksik kalmış
            // olduğu için EF Core onu keşfedemiyordu — bu yüzden yeni/boş
            // veritabanlarında (ör. Railway) FcmToken kolonu hiç oluşmuyordu.
            // IF NOT EXISTS ile hem eksik olan yerlerde ekliyor hem de zaten
            // kolonu olan (ör. yerel geliştirme) veritabanlarında güvenle no-op.
            migrationBuilder.Sql(
                "ALTER TABLE \"Users\" ADD COLUMN IF NOT EXISTS \"FcmToken\" text;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                "ALTER TABLE \"Users\" DROP COLUMN IF EXISTS \"FcmToken\";");
        }
    }
}
