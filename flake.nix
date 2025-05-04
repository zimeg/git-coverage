{
  description = "open test coverage in a web browser";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        kcov = if pkgs.stdenv.isLinux then pkgs.kcov else null;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "git-coverage";
          version = "unversioned";
          src = ./.;
          nativeBuildInputs = [
            pkgs.zig.hook
          ];
          zigBuildFlags = [ "-Doptimize=ReleaseSmall" ];
        };
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.git # https://github.com/git/git
            kcov # https://github.com/SimonKagstrom/kcov
            pkgs.zig # https://github.com/ziglang/zig
          ];
        };
      }
    );
}
