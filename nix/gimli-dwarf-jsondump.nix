{ lib
, rustPlatform
, certoraSource
}:

rustPlatform.buildRustPackage {
  pname = "gimli-dwarf-jsondump";
  version = "0.1.0";

  src = "${certoraSource}/scripts/Gimli-DWARF-JSONDump";

  # cargoHash since cargoLock.lockFile doesn't work well with store paths
  cargoHash = "sha256-RNvrqD2gpFbRqSsa9N7ihRAtSKzZlnbUgzC1BCMeLtk=";

  meta = {
    description = "DWARF debug info JSON dumper for the Certora Prover";
    homepage = "https://github.com/Certora/CertoraProver";
    license = lib.licenses.gpl3Only;
    mainProgram = "Gimli-DWARF-JSONDump";
  };
}
