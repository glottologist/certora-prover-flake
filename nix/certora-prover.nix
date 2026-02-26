{ lib
, symlinkJoin
, makeWrapper
, certoraPython
, tacOptimizer
, gimliDwarfJsondump
, jdk21
, z3
, cvc5
, cvc4
, yices
, bitwuzla
, version
, entryPointNames
}:

let
  runtimePath = lib.makeBinPath [
    jdk21
    z3
    cvc5
    cvc4
    yices
    bitwuzla
    tacOptimizer
    gimliDwarfJsondump
  ];
in
symlinkJoin {
  name = "certora-prover-${version}";

  paths = [
    certoraPython
    tacOptimizer
    gimliDwarfJsondump
  ];

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    for cmd in ${entryPointNames}; do
      if [ -f "$out/bin/$cmd" ]; then
        wrapProgram "$out/bin/$cmd" \
          --prefix PATH : "${runtimePath}"
      fi
    done
  '';

  meta = {
    description = "Certora Prover - formal verification for smart contracts";
    homepage = "https://github.com/Certora/CertoraProver";
    license = lib.licenses.gpl3Only;
    mainProgram = "certoraRun";
    platforms = lib.platforms.linux;
  };
}
