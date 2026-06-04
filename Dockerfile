# ── Build stage ──────────────────────────────────────────────────────────────
FROM golang:1.22-alpine AS builder

WORKDIR /build

# Dependency layer (cached until go.mod changes)
COPY go.mod ./
RUN go mod download

# Compile a fully static binary (no libc dependency in final image)
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server .

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM scratch

# Add a minimal passwd file so we can declare a non-root user
COPY --from=builder /etc/passwd /etc/passwd

# Copy only the compiled binary — no sources, no toolchain
COPY --from=builder /build/server /server

USER nobody

EXPOSE 8080

CMD ["/server"]
