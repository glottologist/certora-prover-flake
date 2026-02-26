{
  description = "Nix flake for the Certora Prover - formal verification for smart contracts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # Certora Prover targets Linux x86_64 primarily
      supportedSystems = [ "x86_64-linux" ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        version = "8.8.0";

        # palantir/gradle-git-version plugin requires a .git directory with version tag
        gitVersionSetup = ''
          git init
          git config user.email "nix@build"
          git config user.name "nix"
          git add -A
          git commit -m "nix build" --quiet
          git tag ${version}
        '';

        # JDK 21 overrides for Gradle (project expects 19, but 21 is compatible)
        gradleProperties = ''
          org.gradle.java.installations.auto-detect=false
          org.gradle.java.installations.auto-download=false
          org.gradle.java.installations.paths=${pkgs.jdk21}/lib/openjdk
          java.version=21
          kotlin.warningsAsErrors=false
        '';

        entryPointNames = "certoraRun certoraMutate certoraEqCheck certoraSolanaProver certoraSorobanProver certoraEVMProver certoraRanger certoraSuiProver certoraCVLFormatter";

        certoraSource = pkgs.callPackage ./nix/certora-source.nix {
          inherit version;
        };

        # outputHash must be recomputed when dependencies change (see nix/gradle-deps.nix)
        gradleDeps = pkgs.callPackage ./nix/gradle-deps.nix {
          inherit certoraSource version gitVersionSetup gradleProperties;
          jdk21 = pkgs.jdk21;
        };

        certoraJvm = pkgs.callPackage ./nix/certora-jvm.nix {
          inherit certoraSource gradleDeps version gitVersionSetup gradleProperties;
          jdk21 = pkgs.jdk21;
        };

        tacOptimizer = pkgs.callPackage ./nix/tac-optimizer.nix {
          inherit certoraSource;
          inherit (pkgs) rustPlatform;
        };

        gimliDwarfJsondump = pkgs.callPackage ./nix/gimli-dwarf-jsondump.nix {
          inherit certoraSource;
          inherit (pkgs) rustPlatform;
        };

        certoraPython = pkgs.callPackage ./nix/certora-python.nix {
          inherit certoraSource certoraJvm tacOptimizer gimliDwarfJsondump version entryPointNames;
          inherit (pkgs) python3Packages;
        };

        certora-prover = pkgs.callPackage ./nix/certora-prover.nix {
          inherit certoraPython tacOptimizer gimliDwarfJsondump version entryPointNames;
          inherit (pkgs) jdk21 z3 cvc5 cvc4 yices bitwuzla;
        };
      in
      {
        packages = {
          default = certora-prover;
          inherit certora-prover;
          inherit tacOptimizer;
          inherit gimliDwarfJsondump;
          inherit certoraJvm;

          gradle-deps = gradleDeps;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            certora-prover
            pkgs.jdk21
            pkgs.z3
            pkgs.cvc5
            pkgs.cvc4
            pkgs.yices
            pkgs.bitwuzla
          ];

          shellHook = ''
            echo "Certora Prover development shell"
            echo "Available commands: certoraRun, certoraMutate, certoraEqCheck, ..."
            echo "JDK: $(java -version 2>&1 | head -1)"
            echo "z3: $(z3 --version)"
          '';
        };
      }
    ) // {
      overlays.default = final: prev: {
        certora-prover = self.packages.${prev.system}.certora-prover;
        tac-optimizer = self.packages.${prev.system}.tacOptimizer;
        gimli-dwarf-jsondump = self.packages.${prev.system}.gimliDwarfJsondump;
      };
    };
}
