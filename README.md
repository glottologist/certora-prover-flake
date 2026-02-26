# certora-prover-flake

A Nix flake that builds the [Certora Prover](https://github.com/Certora/CertoraProver) from source — formal verification for smart contracts.

## Prerequisites

- [Nix](https://nixos.org/download/) with [flakes enabled](https://nixos.wiki/wiki/Flakes)

## Quick Start

```bash
# Try it without installing
nix run github:glottologist/certora-prover-flake -- --help

# Enter a development shell with all tools
nix develop github:glottologist/certora-prover-flake

# Build the package
nix build github:glottologist/certora-prover-flake
```

## What's Included

| Component | Description |
|-----------|-------------|
| `certoraRun` | Main verification entry point |
| `certoraMutate` | Mutation testing |
| `certoraEqCheck` | Equivalence checking |
| `certoraEVMProver` | EVM-specific prover |
| `certoraSolanaProver` | Solana-specific prover |
| `certoraSorobanProver` | Soroban-specific prover |
| `certoraSuiProver` | Sui-specific prover |
| `certoraRanger` | Range analysis |
| `certoraCVLFormatter` | CVL code formatter |

All entry points are wrapped with runtime dependencies (JDK 21, z3, cvc5, cvc4, yices, bitwuzla) on `PATH`.

## NixOS Integration

Use the overlay in your NixOS or home-manager configuration:

```nix
{
  inputs.certora-prover.url = "github:glottologist/certora-prover-flake";

  outputs = { self, nixpkgs, certora-prover, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        {
          nixpkgs.overlays = [ certora-prover.overlays.default ];
          environment.systemPackages = [ pkgs.certora-prover ];
        }
      ];
    };
  };
}
```

## Version Bumping

All version references are centralized in `flake.nix` (`version = "X.Y.Z"`). To update:

1. Change `version` in `flake.nix`
2. Update the source hash in `nix/certora-source.nix` (set to `lib.fakeHash`, build, copy real hash)
3. Update the graphcore submodule rev/hash if changed
4. Update the gradle-deps hash: set to `lib.fakeHash` in `nix/gradle-deps.nix`, run `nix build .#gradle-deps`, copy the real hash
5. Verify: `nix build && ./result/bin/certoraRun --help`

## Packages

Individual components are exposed for advanced use:

```bash
nix build .#certoraJvm          # JVM JARs only
nix build .#tacOptimizer        # Rust TAC optimizer only
nix build .#gimliDwarfJsondump  # Rust DWARF dumper only
nix build .#gradle-deps         # Gradle dependency cache (for hash updates)
```

## Upstream Documentation

- [Certora Prover Docs](https://docs.certora.com/en/latest/)
- [CVL Specification Language](https://docs.certora.com/en/latest/docs/cvl/index.html)

## License

GPL-3.0-only (same as upstream)
