{ lib
, rustPlatform
, certoraSource
}:

rustPlatform.buildRustPackage {
  pname = "tac-optimizer";
  version = "0.1.0";

  src = "${certoraSource}/fried-egg";

  # Upstream repo doesn't include a Cargo.lock for this crate.
  # We supply a pre-generated one. The rust-evm git dependency
  # requires an explicit outputHash.
  cargoLock = {
    lockFile = ./fried-egg-Cargo.lock;
    outputHashes = {
      "rust-evm-0.1.0" = "sha256-IwrgUjOrckhh2rRxQ3PlmfdElHvDCtsBNaYhO0QaCec=";
    };
  };

  postUnpack = ''
    cp ${./fried-egg-Cargo.lock} $sourceRoot/Cargo.lock
  '';

  meta = {
    description = "TAC optimizer for the Certora Prover using e-graphs";
    homepage = "https://github.com/Certora/CertoraProver";
    license = lib.licenses.gpl3Only;
    mainProgram = "tac_optimizer";
  };
}
