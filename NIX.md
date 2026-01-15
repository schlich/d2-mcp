# Using d2-mcp with Nix

This document provides detailed instructions for using d2-mcp with Nix flakes.

## Prerequisites

- [Nix](https://nixos.org/) installed with flakes enabled
- To enable flakes, add to your Nix configuration or use `--experimental-features 'nix-command flakes'`

## Quick Start

### Running without installation

```bash
# Run the server in stdio mode (default)
nix run github:h0rv/d2-mcp

# Run with specific image type
nix run github:h0rv/d2-mcp -- --image-type svg

# Run with SSE transport
nix run github:h0rv/d2-mcp#sse

# Run with HTTP transport
nix run github:h0rv/d2-mcp#http
```

### Installing

```bash
# Install to your user profile
nix profile install github:h0rv/d2-mcp

# Now you can run it directly
d2-mcp --help
```

## Building from Source

### Clone and build

```bash
git clone https://github.com/h0rv/d2-mcp.git
cd d2-mcp

# Build the package
nix build

# The binary will be in ./result/bin/d2-mcp
./result/bin/d2-mcp --help
```

### First-time build: Updating vendorHash

When you first run `nix build`, you'll get an error showing the expected `vendorHash`. This is normal:

```
error: hash mismatch in fixed-output derivation '/nix/store/...':
  specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  got:        sha256-XYZ123...
```

Copy the hash after `got:` and update the `vendorHash` in `flake.nix`:

```nix
vendorHash = "sha256-XYZ123...";  # Use the hash from the error
```

Then run `nix build` again.

## Development

### Enter development shell

```bash
cd d2-mcp
nix develop

# You now have access to:
# - go (Go compiler)
# - imagemagick (for PNG rendering)
# - gopls (Go language server)
# - gotools (Go development tools)
# - go-tools (staticcheck, etc.)
```

### Building within dev shell

```bash
nix develop
go build .
./d2-mcp --help
```

## Using with MCP Clients

### Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
    "mcpServers": {
        "d2": {
            "command": "nix",
            "args": ["run", "github:h0rv/d2-mcp", "--", "--image-type", "png"]
        }
    }
}
```

### Using a local checkout

```json
{
    "mcpServers": {
        "d2": {
            "command": "nix",
            "args": ["run", "/absolute/path/to/d2-mcp", "--", "--image-type", "svg"]
        }
    }
}
```

### Using an installed binary

```bash
# First install to profile
nix profile install github:h0rv/d2-mcp

# Then find the path
which d2-mcp
# Output: /nix/store/.../bin/d2-mcp

# Use this path in your config
{
    "mcpServers": {
        "d2": {
            "command": "/nix/store/.../bin/d2-mcp",
            "args": ["--image-type", "png"]
        }
    }
}
```

## Available Apps

The flake provides three apps:

1. **default**: Standard stdio mode
   ```bash
   nix run github:h0rv/d2-mcp
   ```

2. **sse**: SSE transport on port 8080
   ```bash
   nix run github:h0rv/d2-mcp#sse
   ```

3. **http**: HTTP transport on port 8080
   ```bash
   nix run github:h0rv/d2-mcp#http
   ```

## Runtime Dependencies

The Nix package automatically includes:

- **ImageMagick**: For PNG rendering support
  - The binary is wrapped to ensure `magick` or `convert` is in PATH
  - If PNG rendering fails, check that ImageMagick is working: `magick --version`

## Supported Platforms

The flake supports all systems via `flake-utils.lib.eachDefaultSystem`:

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Troubleshooting

### Build fails with hash mismatch

This is expected on first build. See "First-time build: Updating vendorHash" above.

### ImageMagick not found at runtime

The Nix package should handle this automatically, but if you see errors:

```bash
# Verify ImageMagick is available
nix run github:h0rv/d2-mcp -- --help
magick --version  # Should work
```

### Flakes not enabled

If you get "unrecognized flag: --experimental-features", enable flakes:

```bash
# Temporary (for one command)
nix --experimental-features 'nix-command flakes' run github:h0rv/d2-mcp

# Permanent (add to ~/.config/nix/nix.conf)
experimental-features = nix-command flakes
```

## Updating

### Updating from GitHub

```bash
# Update flake inputs
nix flake update

# Or update nixpkgs specifically
nix flake lock --update-input nixpkgs
```

### Updating installed package

```bash
# Update to latest
nix profile upgrade d2-mcp

# Or reinstall
nix profile remove d2-mcp
nix profile install github:h0rv/d2-mcp
```

## Integration with NixOS

Add to your NixOS configuration:

```nix
{
  environment.systemPackages = [
    (pkgs.callPackage /path/to/d2-mcp/flake.nix {})
  ];
}
```

Or use it in a project's `shell.nix`:

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    (import /path/to/d2-mcp/flake.nix).packages.${pkgs.system}.default
  ];
}
```

## Contributing

When modifying the flake:

1. Make your changes to `flake.nix`
2. Test the build: `nix build`
3. Test the apps: `nix run .#default`, `nix run .#sse`, etc.
4. Test the dev shell: `nix develop`
5. If dependencies change, update `vendorHash` as described above
