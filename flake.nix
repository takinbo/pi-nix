{
  description = "Nix flake for pi - an AI coding agent from pi-mono";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    {
      overlays.default = final: prev: {
        pi = self.packages.${final.stdenv.hostPlatform.system}.pi;
      };
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        pi = pkgs.buildNpmPackage rec {
          pname = "pi";
          version = "0.67.6";

          src = pkgs.fetchFromGitHub {
            owner = "badlogic";
            repo = "pi-mono";
            rev = "v${version}";
            hash = "sha256-e9wQlGzveYrY4BWpRq1xq2PYjn5ZK7/hdnWgx7DMkLA=";
          };

          npmDepsHash = "sha256-wH/eN20rOLGujWY+YTRul/AEq9Ta9/kA5GU0PmiDYM8=";

          nodejs = pkgs.nodejs_22;

          nativeBuildInputs = with pkgs; [
            pkg-config
            python3
            makeWrapper
          ];

          # Native dependencies for the canvas npm package (indirect dependency)
          buildInputs = with pkgs; [
            cairo
            pango
            libjpeg
            giflib
            librsvg
            pixman
          ];

          # Build all packages in the monorepo
          npmBuildScript = "build";

          # Skip generate-models since it requires network access
          preBuild = ''
            substituteInPlace packages/ai/package.json \
              --replace-fail '"build": "npm run generate-models && tsgo -p tsconfig.build.json"' \
                             '"build": "tsgo -p tsconfig.build.json"'
          '';

          dontNpmInstall = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/node_modules/pi-monorepo
            cp -r . $out/lib/node_modules/pi-monorepo/

            # Clean up broken workspace symlinks
            find $out/lib/node_modules/pi-monorepo/node_modules/.bin -xtype l -delete 2>/dev/null || true

            mkdir -p $out/bin

            makeWrapper ${nodejs}/bin/node $out/bin/pi \
              --add-flags "$out/lib/node_modules/pi-monorepo/packages/coding-agent/dist/cli.js" \
              --prefix PATH : ${pkgs.lib.makeBinPath [
                pkgs.ripgrep
                pkgs.fd
                pkgs.git
              ]}

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "An AI coding agent CLI with read, bash, edit, write tools and session management";
            homepage = "https://github.com/badlogic/pi-mono";
            license = licenses.mit;
            maintainers = [];
            platforms = platforms.unix;
          };
        };

      in {
        packages = {
          default = pi;
          pi = pi;
        };

        apps.default = {
          type = "app";
          program = "${pi}/bin/pi";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs_22
            ripgrep
            fd
            git
          ];
        };
      }
    );
}
