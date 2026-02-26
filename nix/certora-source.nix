{ lib, stdenvNoCC, fetchFromGitHub, version }:

let
  mainSrc = fetchFromGitHub {
    owner = "Certora";
    repo = "CertoraProver";
    rev = version;
    hash = "sha256-nfbEvyG3h/HtA/HI9XrianzCwYznIZkdIXIgk0LJdDM=";
  };

  # graphcore submodule uses SSH URL in .gitmodules, so fetch separately
  graphcoreSrc = fetchFromGitHub {
    owner = "Certora";
    repo = "graphcore";
    rev = "f7c79950461e8608b6f59d1e13c8c61c0bf6b4f2";
    hash = "sha256-ZQdNngxHcWIaSHgoV/phaZXBUj1c7uVZMEmu7XgKlRU=";
  };
in

stdenvNoCC.mkDerivation {
  pname = "certora-prover-source";
  inherit version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp -r ${mainSrc} $out
    chmod -R u+w $out
    rm -rf $out/scripts/graphcore
    cp -r ${graphcoreSrc} $out/scripts/graphcore
  '';
}
