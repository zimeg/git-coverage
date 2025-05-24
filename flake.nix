{
  description = "open test coverage in a web browser";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs =
    { nixpkgs, ... }:
    let
      each =
        function:
        nixpkgs.lib.genAttrs [
          "x86_64-darwin"
          "x86_64-linux"
          "aarch64-darwin"
          "aarch64-linux"
        ] (system: function nixpkgs.legacyPackages.${system});
    in
    {
      devShells = each (
        pkgs:
        let
          kcov = if pkgs.stdenv.isLinux then pkgs.kcov else null;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.git # https://github.com/git/git
              pkgs.goreleaser # https://github.com/goreleaser/goreleaser
              kcov # https://github.com/SimonKagstrom/kcov
              pkgs.zig # https://github.com/ziglang/zig
            ];
          };
        }
      );
      packages = each (pkgs: {
        default = pkgs.stdenv.mkDerivation {
          pname = "git-coverage";
          version = "unversioned";
          src = ./.;
          nativeBuildInputs = [
            pkgs.installShellFiles
            pkgs.zig.hook
          ];
          zigBuildFlags = [ "-Doptimize=ReleaseSmall" ];
          installPhase = ''
            mkdir -p $out/bin
            cp zig-out/bin/git-coverage $out/bin/
            installManPage man/git-coverage.1
          '';
        };
      });
    };
}
