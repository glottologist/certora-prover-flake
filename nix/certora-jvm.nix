{ lib
, stdenv
, git
, jdk21
, certoraSource
, gradleDeps
, version
, gitVersionSetup
, gradleProperties
}:

stdenv.mkDerivation {
  pname = "certora-jvm";
  inherit version;

  src = certoraSource;

  nativeBuildInputs = [ git jdk21 ];

  JAVA_HOME = "${jdk21}/lib/openjdk";

  postUnpack = ''
    cd $sourceRoot
    ${gitVersionSetup}
    cd ..
  '';

  buildPhase = ''
    runHook preBuild

    export GRADLE_USER_HOME="$(pwd)/.gradle"

    mkdir -p "$GRADLE_USER_HOME"
    cp -r ${gradleDeps}/caches "$GRADLE_USER_HOME/caches"
    chmod -R u+w "$GRADLE_USER_HOME/caches"

    if [ -d "${gradleDeps}/wrapper" ]; then
      cp -r ${gradleDeps}/wrapper "$GRADLE_USER_HOME/wrapper"
      chmod -R u+w "$GRADLE_USER_HOME/wrapper"
    fi

    if [ -d "${gradleDeps}/native" ]; then
      cp -r ${gradleDeps}/native "$GRADLE_USER_HOME/native"
      chmod -R u+w "$GRADLE_USER_HOME/native"
    fi

    chmod +x gradlew

    cat >> gradle.properties <<EOF
    ${gradleProperties}
    EOF

    ./gradlew --no-daemon \
      --offline \
      -Dorg.gradle.java.home=${jdk21}/lib/openjdk \
      shadowJar \
      :Typechecker:shadowJar \
      :ASTExtraction:shadowJar \
      -x fried-egg \
      -x gimli-dwarf-jsondump

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib

    # Root project: archiveClassifier = "jar-with-dependencies"
    cp build/libs/emv-*-jar-with-dependencies.jar $out/lib/emv.jar

    # Subproject shadow JARs use default "-all" classifier
    cp Typechecker/build/libs/*-all.jar $out/lib/Typechecker.jar
    cp ASTExtraction/build/libs/*-all.jar $out/lib/ASTExtraction.jar

    for jar in emv.jar Typechecker.jar ASTExtraction.jar; do
      if [ ! -f "$out/lib/$jar" ]; then
        echo "ERROR: $jar was not produced by the build"
        exit 1
      fi
    done

    runHook postInstall
  '';

  meta = {
    description = "Certora Prover JVM components (EMV, Typechecker, AST Extraction)";
    homepage = "https://github.com/Certora/CertoraProver";
    license = lib.licenses.gpl3Only;
  };
}
