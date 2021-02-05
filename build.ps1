$IMAGE_NAME_AND_TAG="weatherforecast-api:latest"

Write-Output "App [build]"
docker build -t $IMAGE_NAME_AND_TAG .