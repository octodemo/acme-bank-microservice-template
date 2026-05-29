# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/dotnet/sdk:10.0@sha256:c0790639332692a0d56cdd81ed581cfd24d040d9839764c138994866df89a3b6 AS build
WORKDIR /src

COPY Directory.Build.props Directory.Packages.props global.json ./
COPY src/MyService/MyService.csproj src/MyService/
RUN dotnet restore src/MyService/MyService.csproj

COPY src/MyService src/MyService
RUN dotnet publish src/MyService/MyService.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0@sha256:8c0b6857eab7b2aa57884c839bf4678414606bd7d17370f18a842ac5cf414711 AS final
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
COPY --from=build /app/publish .
USER app
ENTRYPOINT ["dotnet", "MyService.dll"]
