{ lib
, stdenv
, git
, jdk21
, cacert
, certoraSource
, version
, gitVersionSetup
, gradleProperties
}:

# Fixed-output derivation that downloads all Gradle/Maven dependencies.
# Uses the project's Gradle wrapper (gradlew) to get the correct Gradle
# version (7.2). The outputHash must be computed once per version. To update:
#   1. Set outputHash = lib.fakeHash
#   2. Run: nix build .#gradle-deps
#   3. Copy the hash from the error message
#   4. Replace lib.fakeHash with the real hash
stdenv.mkDerivation {
  pname = "certora-gradle-deps";
  inherit version;

  src = certoraSource;

  nativeBuildInputs = [ git jdk21 ];

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "sha256-YN8ginUHZemFizofCY3gePFXUe1x1dAoBtWJh3K1fv8=";

  SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  GIT_SSL_CAINFO = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  # nixpkgs JDK has the actual JDK home nested at lib/openjdk/
  JAVA_HOME = "${jdk21}/lib/openjdk";

  buildPhase = ''
    runHook preBuild

    export GRADLE_USER_HOME="$(pwd)/.gradle"

    chmod +x gradlew

    ${gitVersionSetup}

    cat >> gradle.properties <<PROPS
    ${gradleProperties}
    PROPS

    # Build tasks force all artifact downloads; build may fail for
    # non-dependency reasons, but all needed Maven artifacts get cached.
    ./gradlew --no-daemon \
      -Dorg.gradle.java.home=${jdk21}/lib/openjdk \
      shadowJar \
      :Typechecker:shadowJar \
      :ASTExtraction:shadowJar \
      -x fried-egg \
      -x gimli-dwarf-jsondump \
      || true

    ./gradlew --no-daemon \
      -Dorg.gradle.java.home=${jdk21}/lib/openjdk \
      buildEnvironment \
      || true

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    if [ -d ".gradle/caches" ]; then
      cp -r .gradle/caches $out/caches
    fi

    if [ -d ".gradle/wrapper" ]; then
      cp -r .gradle/wrapper $out/wrapper
    fi

    if [ -d ".gradle/native" ]; then
      cp -r .gradle/native $out/native
    fi

    # Remove non-deterministic artifacts
    find $out -name "*.lock" -delete || true
    find $out -name "gc.properties" -delete || true
    find $out -name "journal-*" -delete || true
    find $out -type d -name "daemon" -exec rm -rf {} + || true

    runHook postInstall
  '';

  dontFixup = true;
}
