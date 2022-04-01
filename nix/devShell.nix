{
  mkShell,
  buildInputs,
  nativeBuildInputs,
}:
mkShell {
  name = "conduit-dev-env";
  inherit buildInputs nativeBuildInputs;
  ### Environment Variables
  RUST_BACKTRACE = 1;
}
