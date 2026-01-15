{
  description = "A Model Context Protocol (MCP) server for D2 diagramming";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          default = pkgs.buildGoModule {
            pname = "d2-mcp";
            version = "1.0.0";

            src = ./.;

            # To update this hash, run: nix build .#default
            # The error message will show the correct hash to use
            vendorHash = pkgs.lib.fakeHash;

            # Runtime dependencies for PNG rendering
            buildInputs = [ pkgs.imagemagick ];

            # Set CGO_ENABLED if needed by dependencies
            CGO_ENABLED = 0;

            # Ensure ImageMagick is available at runtime
            postInstall = ''
              wrapProgram $out/bin/d2-mcp \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.imagemagick ]}
            '';

            nativeBuildInputs = [ pkgs.makeWrapper ];

            meta = with pkgs.lib; {
              description = "Model Context Protocol server for D2 diagramming";
              homepage = "https://github.com/h0rv/d2-mcp";
              license = licenses.mit;
              maintainers = [ ];
              mainProgram = "d2-mcp";
            };
          };
        };

        # Development shell with all necessary tools
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            imagemagick
            gopls
            gotools
            go-tools
          ];

          shellHook = ''
            echo "d2-mcp development environment"
            echo "Go version: $(go version)"
            echo "ImageMagick: $(command -v magick >/dev/null && magick --version | head -n1 || echo 'not found')"
          '';
        };

        # Apps for easy running
        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/d2-mcp";
          };

          # Run with SSE transport
          sse = {
            type = "app";
            program = "${pkgs.writeShellScript "d2-mcp-sse" ''
              ${self.packages.${system}.default}/bin/d2-mcp --transport sse --port 8080
            ''}";
          };

          # Run with HTTP transport
          http = {
            type = "app";
            program = "${pkgs.writeShellScript "d2-mcp-http" ''
              ${self.packages.${system}.default}/bin/d2-mcp --transport http --port 8080
            ''}";
          };
        };
      }
    );
}
