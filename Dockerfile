# This Docker setup solves several issues which arise when building Rust
# applications in Docker:
#
# 1. Big image size
#		
#	This one can be solved by having a "builder" image with all the dependencies
#	that builds an executable file which we copy into a "runtime" image that
#	provides dynamic libraries, SSL certificates etc.
# 	To reduce setup complexity of the runtime image, we can compile statically
# 	so that the executable is as self-contained as possible.
#	Chosen base builder image `ekidd/rust-musl-builder` helps with building
#	statically in Docker (https://hub.docker.com/r/ekidd/rust-musl-builder).
#
# 2. Rebuilding everything including dependencies every time our code changes
#
# 	This is solved by first copying `Cargo.toml` and `Cargo.lock` files (step 1),
# 	building the dependencies (step 2), copying our code to the image (step 3)
#	and lastly by building our application (step 4). When our code changes,
#	Docker only has to redo step 3 and 4. Of course, when we update our
#	dependencies, we have to redo steps 1-4, but that doesn't happen on a daily
# 	basis.
#
# 3. Various issues with OpenSSL
#
#	As of writing this, I don't have sufficient understanding of how libraries
#	that we depend on use OpenSSL on a technical level and why issues with it
#	arise in Docker.
#	This, again, is solved by the amazing `ekidd/rust-musl-builder`.
#

### This is the builder image
FROM ekidd/rust-musl-builder:latest AS builder

# Compilation is slightly faster with linker `lld`
RUN sudo apt update && sudo apt install lld -y
ENV RUSTFLAGS="-C link-args=-fuse-ld=lld"

# The following block makes sure we don't recompile dependencies every time
# we change our code
RUN cargo init
# The `--chown` is required because of the way our builder image handles users.
COPY --chown=rust:rust Cargo.toml Cargo.lock ./
# Build dependencies
RUN cargo build --release

# Add our source code
ADD --chown=rust:rust . ./

# Build our application
RUN cargo build --release

# Decrease the size by more than 50%
RUN objcopy --compress-debug-sections ./target/x86_64-unknown-linux-musl/release/musl-builder-m1-check

### This is the runtime image
# Alpine is one of the smallest images available while providing capabilities
# like package installation.
FROM alpine:latest AS runtime

COPY ./entrypoint.sh ./expand-secrets.sh ./
RUN apk --no-cache add ca-certificates

# `web_server` is a statically built binary
COPY --from=builder \
    /home/rust/src/target/x86_64-unknown-linux-musl/release/musl-builder-m1-check \
    /usr/local/bin/

# define var containing git short hash that should be set in docker build command
ARG GIT_SHA_SHORT
ENV GIT_SHA_SHORT=$GIT_SHA_SHORT

ENTRYPOINT [ "./entrypoint.sh" ]
CMD [ "/usr/local/bin/web_server" ]
