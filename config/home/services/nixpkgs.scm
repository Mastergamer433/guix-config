(define-module (config home services nixpkgs)
  #:use-module (gnu services)
  #:use-module (gnu home services)
  #:use-module (config utils)
  #:export (home-nixpkgs-service-type))

(define (home-nixpkgs-files-service config)
  `((" .config/nixpkgs/config.nix" ,(service-config-file "config.nix"))))

(define-public home-nixpkgs-service-type
  (service-type (name 'home-nixpkgs)

                (extensions (list (service-extension home-files-service-type
                                   home-nixpkgs-files-service)))

                (default-value #f)

                (description "Install the user's Nixpkgs configuration.")))
