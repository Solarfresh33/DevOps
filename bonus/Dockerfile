# Stage 1 – compile the hand-crafted ELF binary with NASM
FROM ubuntu:24.04 AS builder
RUN apt-get update -qq && apt-get install -y -qq nasm
COPY tiny.asm /
RUN nasm -f bin -o /tiny /tiny.asm && chmod +x /tiny

# Stage 2 – copy the raw binary into an empty image (scratch = 0 bytes of base)
FROM scratch
COPY --from=builder /tiny /tiny
ENTRYPOINT ["/tiny"]
