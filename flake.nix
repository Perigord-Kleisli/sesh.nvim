{
  description = "A Neovim Session Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [(self: super: {fennel-language-server = super.callPackage ./fennel-language-server.nix {};})];
        };
      in
        with pkgs; {
          devShells.default = mkShell {
            buildInputs = [
              fennel
              gnumake
              marksman
              python39
              nodePackages.prettier
              nodejs
              fennel-language-server
              fnlfmt
              neovim
            ];
          };
        }
    );
}
