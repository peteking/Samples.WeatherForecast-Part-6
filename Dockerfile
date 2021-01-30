ARG VERSION=5.0-alpine

FROM mcr.microsoft.com/dotnet/sdk:${VERSION} AS build
WORKDIR /app

# Copy and restore as distinct layers
COPY . .
WORKDIR /app/src/Samples.WeatherForecast.Api
RUN dotnet restore Samples.WeatherForecast.Api.csproj -r linux-musl-x64
RUN dotnet build

FROM build AS testrunner
WORKDIR /app/test/Samples.WeatherForecast.Api.UnitTest
ENTRYPOINT ["dotnet", "test", "--logger:trx"]

FROM build AS test
WORKDIR /app/test/Samples.WeatherForecast.Api.UnitTest
RUN dotnet test --logger:trx

FROM build AS publish
WORKDIR /app/src/Samples.WeatherForecast.Api
RUN dotnet publish \
    -c Release \
    -o /out \
    -r linux-musl-x64 \
    --self-contained=true \
    -- no-restore \
    -- no-build \
    -p:PublishReadyToRun=true \
    -p:PublishTrimmed=true

# Final stage/image
FROM mcr.microsoft.com/dotnet/runtime-deps:${VERSION}

RUN addgroup -S dotnetgroup && \
    adduser -S dotnet
USER dotnet

WORKDIR /app
COPY --chown=dotnet:dotnetgroup --from=publish /out .

EXPOSE 8080

HEALTHCHECK --interval=60s --timeout=3s --retries=3 \
    CMD wget localhost:80/health -q -O - > /dev/null 2>&1

ENTRYPOINT ["./Samples.WeatherForecast.Api"]