# Nexus configurations

For backend storage, I have created two blob stores.

- proxied-rust-static
- proxied-rust-crates-io for proxying cargo crates

For Rust installation of toolchains, channels, and components I have added the
following raw repository.

- proxied-rust-static proxying https://static.rust-lang.org

For cargo crates-io dependency resolution I have added the repositories.

- proxied-rust-crates-io-config *raw hosted repository* where I manually
  uploaded `config.json` for the proxy registry.
  - Inline content
  - This hosted repository should not ever contain anything other than
    `config.json` file.  It is dedicated for serving the Cargo crate index
    config.
- proxied-rust-crates-io-index *raw proxy repository* which is the cargo index
  repository.  It has routing rules.
  - Backend https://index.crates.io
  - Routing rule rust-crates-index
  - Inline content
- proxied-rust-crates-io-api *raw proxy repository* which is where crate assets
  are downloaded from after cargo queries the index.
  - Backend https://crates.io
  - Routing rule rust-crates-download
  - Attachment content
- proxied-rust-crates-io *raw repository group* which is the public
  configuration endpoint.  Which has all three of the above repositories in this
  specific order (do not reorder them as the order is important):
  1. proxied-rust-crates-io-config
  2. proxied-rust-crates-io-api
  3. proxied-rust-crates-io-index

Routing rule rust-crates-index defined as `Rust Cargo Dependencies Index routing
rule` with Mode Allow.

```
/([-_0-9a-z]{1,3}/?){1,2}/.*
```

Routing rule rust-crates-download defined as `Rust Cargo Dependencies Download
routing rule` with Mode Allow.

```
/api/v1/crates/([-_.0-9a-z]+/){2}download$
```

proxied-rust-crates-io-config `config.json` contents

```json
{
  "dl": "https://nexus.local/repository/proxied-rust-crates-io/api/v1/crates",
  "api": "https://crates.io"
}
```

- dl - is for downloading crate assets (which we are proxying)
- api - Unfortunately, I can't use Nexus to proxy the crates.io API because
  Nexus won't cleanly pass through query parameters.  If crates.io ever becomes
  unstable we'll need to explore a way to properly proxy the API server as a
  passthrough.

# End user configuration

Rust channels, toolchains, and components should be downloaded through
https://nexus.local/repository/proxied-rust-static/

To properly proxy rustup to install everything via Sonatype Nexus set the
following environment variables.

```
export PATH=~/.cargo/bin:"$PATH"
export RUSTUP_DIST_SERVER=https://nexus.local/repository/proxied-rust-static
```

Cargo crates.io crates can be installed via sparse proxy through https://nexus.local/repository/proxied-rust-crates-io/

`~/.cargo/config` should have the following configuration

```toml
[source.crates-io]
replace-with = "crates-io-mirror"

[registries.crates-io-mirror]
index = "sparse+https://nexus.local/repository/proxied-rust-crates-io/"
```

# Example usage and testing

I played with the Ubuntu Docker image.

```bash
docker run -it --rm ubuntu:22.04
apt-get update
apt-get install -y curl vim gcc
```

And then ran the following commands.

```bash
export PATH=~/.cargo/bin:"$PATH"
export RUSTUP_DIST_SERVER=https://nexus.local/repository/proxied-rust-static


curl -sSfLo /usr/local/bin/rustup-init "$RUSTUP_DIST_SERVER"/rustup/archive/1.26.0/aarch64-unknown-linux-gnu/rustup-init
chmod 755 /usr/local/bin/rustup-init


cat > ~/.cargo/config <<'EOF'
[source.crates-io]
replace-with = "crates-io-mirror"

[registries.crates-io-mirror]
index = "sparse+https://nexus.local/repository/proxied-rust-crates-io/"
EOF


rustup-init -y --no-modify-path --default-toolchain 1.75.0
```

Test compiling and resolving dependencies.

```
# Initialize hello cargo
cargo new hello_cargo
cd hello_cargo
cargo build

# Test our proxied cargo registry for crates.io
echo 'warp = "^0.3.1"' >> Cargo.toml
cargo build
```

# Additional resources

This configuration was configured by reading the following resources.

* https://crates.io/crates/crates-io-proxy
* https://rust-lang.github.io/rustup/
* https://doc.rust-lang.org/cargo/

All of the above covers the knowledge you need and so I utilized Sonatype Nexus
features to implement it.  I hand crafted all of the regular expressions based
on the books definition for how registries and assets should be downloaded.
These are not items easily found.
