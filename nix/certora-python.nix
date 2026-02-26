{ lib
, python3Packages
, certoraSource
, certoraJvm
, tacOptimizer
, gimliDwarfJsondump
, version
, entryPointNames
}:

python3Packages.buildPythonPackage {
  pname = "certora-cli";
  inherit version;
  format = "setuptools";

  src = certoraSource;

  propagatedBuildInputs = with python3Packages; [
    click
    json5
    pycryptodome
    requests
    rich
    sly
    tabulate
    tqdm
    strenum
    jinja2
    wcmatch
    typing-extensions
    setuptools
  ];

  # Restructure the source tree to match the pip package layout.
  # This replicates what certora_cli_publish.py does.
  preBuild = ''
    mkdir -p certora_cli certora_jars certora_bins

    cp -r scripts/CertoraProver certora_cli/CertoraProver
    cp -r scripts/Shared certora_cli/Shared
    cp -r scripts/Mutate certora_cli/Mutate
    cp -r scripts/EquivalenceCheck certora_cli/EquivalenceCheck

    if [ -d scripts/graphcore ]; then
      cp -r scripts/graphcore certora_cli/graphcore
    fi

    for script in ${entryPointNames} certoraConcord rustMutator; do
      if [ -f "scripts/$script.py" ]; then
        cp "scripts/$script.py" certora_cli/
      fi
    done

    for dir in certora_cli certora_jars certora_bins; do
      touch "$dir/__init__.py"
    done

    cp ${certoraJvm}/lib/Typechecker.jar certora_jars/
    cp ${certoraJvm}/lib/ASTExtraction.jar certora_jars/
    cp ${certoraJvm}/lib/emv.jar certora_jars/

    cp ${tacOptimizer}/bin/tac_optimizer certora_bins/
    cp ${gimliDwarfJsondump}/bin/Gimli-DWARF-JSONDump certora_bins/

    cat > certora_jars/CERTORA-CLI-VERSION-METADATA.json << 'METADATA'
    {
      "name": "certora-cli",
      "tag": "${version}",
      "branch": "",
      "commit": "2cf089d",
      "timestamp": "nix-build",
      "version": "${version}"
    }
    METADATA

    cat > setup.py << 'SETUP'
    import setuptools

    setuptools.setup(
        name="certora-cli",
        version="${version}",
        author="Certora",
        author_email="support@certora.com",
        description="Runner for the Certora Prover",
        long_description="Certora Prover CLI - built from source via Nix",
        long_description_content_type="text/markdown",
        url="https://github.com/Certora/CertoraProver",
        packages=setuptools.find_packages(),
        include_package_data=True,
        install_requires=[
            "click",
            "json5",
            "pycryptodome",
            "requests",
            "rich",
            "sly",
            "tabulate",
            "tqdm",
            "StrEnum",
            "jinja2",
            "wcmatch",
            "typing_extensions",
        ],
        project_urls={
            "Documentation": "https://docs.certora.com/en/latest/",
            "Source": "https://github.com/Certora/CertoraProver",
        },
        license="GPL-3.0-only",
        classifiers=[
            "Programming Language :: Python :: 3",
            "License :: OSI Approved :: GNU General Public License v3 (GPLv3)",
            "Operating System :: OS Independent",
        ],
        entry_points={
            "console_scripts": [
                "certoraRun = certora_cli.certoraRun:entry_point",
                "certoraMutate = certora_cli.certoraMutate:mutate_entry_point",
                "certoraEqCheck = certora_cli.certoraEqCheck:equiv_check_entry_point",
                "certoraSolanaProver = certora_cli.certoraSolanaProver:entry_point",
                "certoraSorobanProver = certora_cli.certoraSorobanProver:entry_point",
                "certoraEVMProver = certora_cli.certoraEVMProver:entry_point",
                "certoraRanger = certora_cli.certoraRanger:entry_point",
                "certoraSuiProver = certora_cli.certoraSuiProver:entry_point",
                "certoraCVLFormatter = certora_cli.certoraCVLFormatter:entry_point",
            ]
        },
        python_requires=">=3.9",
    )
    SETUP

    cat > MANIFEST.in << 'MANIFEST'
    recursive-include certora_jars *.jar CERTORA-CLI-VERSION-METADATA.json
    recursive-include certora_bins tac_optimizer Gimli-DWARF-JSONDump
    recursive-include certora_cli *.py *.spec *.conf
    MANIFEST
  '';

  # Don't run the standard configure; we set up the source in preBuild
  dontConfigure = true;

  postInstall = ''
    for cmd in ${entryPointNames}; do
      if [ ! -f "$out/bin/$cmd" ]; then
        echo "WARNING: $cmd entry point not found in $out/bin/"
      fi
    done

    site_packages="$out/lib/python*/site-packages"
    jar_dir=$(echo $site_packages/certora_jars)
    bin_dir=$(echo $site_packages/certora_bins)

    if [ ! -f "$jar_dir/Typechecker.jar" ]; then
      echo "WARNING: Typechecker.jar not found in installed package"
    fi
  '';

  doCheck = false;

  meta = {
    description = "Certora Prover CLI for formal verification of smart contracts";
    homepage = "https://github.com/Certora/CertoraProver";
    license = lib.licenses.gpl3Only;
    mainProgram = "certoraRun";
  };
}
