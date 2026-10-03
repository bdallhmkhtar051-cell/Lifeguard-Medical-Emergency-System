FROM ghcr.io/cirruslabs/flutter:3.35.3 AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY lib ./lib
COPY web ./web

# The public API URL is safe to embed in the browser bundle. Never place
# passwords, signing keys, or database connection strings in this build.
ARG API_BASE_URL=https://stunning-manifestation-production-05f1.up.railway.app
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:1.27-alpine AS runtime
COPY hosting/flutter-nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 8080
