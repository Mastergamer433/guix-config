{
  description = "My user packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fluxer-nix.url = "github:ardishko/fluxer-nix";
  };

  outputs = { nixpkgs, fluxer-nix, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems f;

      packagesFor = { pkgs, hostname }:
        with pkgs;
        [
	  fluxer-nix.packages.${pkgs.system}.fluxer
          bat
          fd
          fzf
          git
          jq
          ripgrep
        ]
        ++ lib.optionals (hostname == "harry-potter") [
          neovim
          tmux
        ];
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          hostnames = [
            "harry-potter"
          ];
        in
        builtins.listToAttrs (map (hostname: {
          name = hostname;
          value = pkgs.buildEnv {
            name = "my-packages-${hostname}";
            paths = packagesFor {
              inherit pkgs hostname;
            };
          };
        }) hostnames)
      );
    };
}
