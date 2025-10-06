# ---- Frontend Build Stage ----
FROM node:20-alpine AS frontend-builder

WORKDIR /frontend

# Copy frontend package files
COPY frontend/package*.json ./
RUN npm install

# Copy frontend source
COPY frontend/ ./

# Build frontend
RUN npm run build

# ---- Backend Build Stage ----
FROM golang:1.25-alpine AS backend-builder

# Install git for go modules
RUN apk add --no-cache git

WORKDIR /go/src/app

# Copy go mod files first (to enable dependency caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source
COPY . .

# Build the Go application
RUN go build -o /go/bin/app -v .

# ---- Final Stage ----
FROM alpine:latest

# Add trusted CA certs for HTTPS requests
RUN apk --no-cache add ca-certificates

# Copy binary from backend builder stage
COPY --from=backend-builder /go/bin/app /app

# Copy built frontend from frontend builder stage
COPY --from=frontend-builder /frontend/dist /frontend/dist

# Security: use non-root user
RUN adduser -D appuser && \
    chown -R appuser:appuser /frontend
USER appuser

# Expose your app port
EXPOSE 8080

# Use JSON form for ENTRYPOINT (handles OS signals correctly)
ENTRYPOINT ["/app"]

# Optional metadata
LABEL Name="egg" Version="0.0.1" Maintainer="jkzilla"
