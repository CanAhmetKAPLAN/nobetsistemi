FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY NobetSistemi.slnx ./
COPY src/NobetSistemi.API/NobetSistemi.API.csproj src/NobetSistemi.API/
COPY src/NobetSistemi.Application/NobetSistemi.Application.csproj src/NobetSistemi.Application/
COPY src/NobetSistemi.Domain/NobetSistemi.Domain.csproj src/NobetSistemi.Domain/
COPY src/NobetSistemi.Infrastructure/NobetSistemi.Infrastructure.csproj src/NobetSistemi.Infrastructure/
RUN dotnet restore src/NobetSistemi.API/NobetSistemi.API.csproj

COPY src/ src/
RUN dotnet publish src/NobetSistemi.API/NobetSistemi.API.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app .

# Railway, konteynere dinlenecek portu PORT ortam değişkeniyle bildirir.
ENTRYPOINT ["sh", "-c", "dotnet NobetSistemi.API.dll --urls http://+:${PORT:-8080}"]
