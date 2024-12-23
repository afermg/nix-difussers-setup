{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs_master.url = "github:NixOS/nixpkgs/master";
    systems.url = "github:nix-systems/default";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    nix-comfyui.url = "github:dyscorv/nix-comfyui";    
  };

  outputs = { self, nixpkgs, flake-utils, systems, ... } @ inputs:
      flake-utils.lib.eachDefaultSystem (system:
        let
            pkgs = import nixpkgs {
              system = system;
              config.allowUnfree = true;
            };

            mpkgs = import inputs.nixpkgs_master {
              system = system;
              config.allowUnfree = true;
            };

            libList = [
                # Add needed packages here
                pkgs.cudaPackages.cudatoolkit
                pkgs.libz # Numpy
                pkgs.stdenv.cc.cc
                pkgs.libGL
                pkgs.glib
                # pkgs.ruff
                # pkgs.ruff-lsp
              ];
          in
          with pkgs;
        {
          devShells = {
            default  = let
              # These packages get built by Nix, and will be ahead on the PATH
                pwp = (python311.withPackages (p: with p; [
                     venvShellHook
                     python-lsp-server
                     python-lsp-ruff
                     diffusers
                     torchWithCuda
                     transformers
                     accelerate
                ]));
            in mkShell {
               NIX_LD = runCommand "ld.so" {} ''
                        ln -s "$(cat '${pkgs.stdenv.cc}/nix-support/dynamic-linker')" $out
                      '';
                NIX_LD_LIBRARY_PATH = lib.makeLibraryPath libList;
                packages = [
                  pwp
                  ruff
                ]
                ++ libList;
                shellHook = ''
                    export PYTHONPATH=${pwp}/${pwp.sitePackages}:$PYTHONPATH
                    export PATH=${pre-commit}/bin:${ruff}/bin:$PATH
                '';
             };
          };
        }
      );
}
