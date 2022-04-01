{
  pkgs,
  crate2nix,
  name,
  src,
}: let
  inherit
    (import "${crate2nix}/tools.nix" {inherit pkgs;})
    generatedCargoNix
    ;

  project =
    import
    (generatedCargoNix {
      inherit name src;
    })
    {
      inherit pkgs;
      buildRustCrateForPkgs = pkgs:
        pkgs.buildRustCrate.override {
          defaultCrateOverrides =
            pkgs.defaultCrateOverrides
            // {
              # Crate dependency overrides go here
              conduit = attrs: {
                inherit name;
              };
            };
        };
    };
in
  project.workspaceMembers.conduit.build
