FROM rust:latest

RUN apt-get update && apt-get install -y libssl-dev pkg-config && cargo install cargo-watch

WORKDIR /app
