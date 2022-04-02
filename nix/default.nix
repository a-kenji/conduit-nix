{
  self,
  nixpkgs,
  conduit,
  rust-overlay,
  flake-utils,
  flake-compat,
  crate2nix,
}:
flake-utils.lib.eachSystem [
  "aarch64-linux"
  "aarch64-darwin"
  "i686-linux"
  "x86_64-darwin"
  "x86_64-linux"
]
(system: let
  overlays = [(import rust-overlay)];

  pkgs = import nixpkgs {inherit system overlays;};

  crate2nixPkgs = import nixpkgs {
    inherit system;
    overlays = [
      (self: _: {
        rustc = rustToolchainToml;
        cargo = rustToolchainToml;
      })
    ];
  };

  name = "conduit";
  pname = name;
  root = conduit;

  ignoreSource = [".git" "target" "example"];

  src = pkgs.nix-gitignore.gitignoreSource ignoreSource root;

  rustToolchainToml = pkgs.rust-bin.fromRustupToolchainFile ../rust-toolchain.toml;
  cargoLockFile = conduit + /Cargo.lock;

  cargo = rustToolchainToml;
  rustc = rustToolchainToml;

  buildInputs = [
    pkgs.rocksdb
  ];

  nativeBuildInputs = [
    pkgs.rustPlatform.bindgenHook
  ];

  devInputs = [
    rustToolchainToml
  ];

  fmtInputs = [
    pkgs.alejandra
    pkgs.treefmt
  ];
  # TODO add meta
in rec {
  # crate2nix - better incremental builds, but uses ifd
  #packages.conduit = crate2nixPkgs.callPackage ./crate2nix.nix {
  #inherit
  #name
  #src
  #crate2nix
  #;
  #};

  # native nixpkgs support - keep supported
  packages.conduit-native = (pkgs.makeRustPlatform {inherit cargo rustc;}).buildRustPackage {
    inherit
      src
      name
      buildInputs
      nativeBuildInputs
      ;
     LIBCLANG_PATH= pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_latest.libclang.lib ];
    cargoLock = {
      lockFile = src + "/Cargo.lock";
      outputHashes = {
        "heed-0.10.6" = "sha256-rm02pJ6wGYN4SsAbp85jBVHDQ5ITjZZd+79EC2ubRsY=";
        "reqwest-0.11.9" = "sha256-wH/q7REnkz30ENBIK5Rlxnc1F6vOyuEANMHFmiVPaGw";
        "ruma-0.4.0" = "sha256-gRhhGWpMiLeA8TNgBMsFEBky1TISr/GXNxLpTXLgUQE";
      };
    };
  };

  defaultPackage = packages.conduit-native;

  # nix run
  apps.conduit = flake-utils.lib.mkApp {drv = packages.conduit;};
  defaultApp = apps.conduit;

  devShells = {
    conduit = pkgs.callPackage ./devShell.nix {
      inherit buildInputs;
      nativeBuildInputs = nativeBuildInputs ++ devInputs ++ fmtInputs;
    };
    fmtShell = pkgs.mkShell {
      name = "fmt-shell";
      nativeBuildInputs = fmtInputs;
    };
  };

  devShell = devShells.conduit;
})
