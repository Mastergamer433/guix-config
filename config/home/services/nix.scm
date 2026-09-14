(define-module (config home services nix)
  #:use-module (gnu packages package-management)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:use-module (config utils)
  #:export (home-nix-configuration home-nix-service-type))

(define-configuration/no-serialization home-nix-configuration
                                       (flake (string "./nix-flake")
                                              "Path to the Nix flake.")

                                       (profile (string
                                                 "~/.local/state/nix/profiles/my-nix")
                                                "Path to the Nix profile."))

(define (home-nix-profile-service config)
  (list nix))

(define (home-nix-files-service config)
  `((" .config/nix/nix.conf" ,(service-config-file "nix.conf"))))

(define (home-nix-activation-service config)
  (let ((flake (home-nix-configuration-flake config))
        (profile (home-nix-configuration-profile config)))
    #~(begin
        (use-modules (guix build utils))

        (let ((profile (if (string-prefix? "~/"
                                           #$profile)
                           (string-append (getenv "HOME")
                                          (substring #$profile 1))
                           #$profile)))
          
          (format #t "Installing Nix flake into ~a~%" profile)

          (invoke #$(file-append nix "/bin/nix")
                  "profile"
                  "install"
                  "--profile"
                  profile
                  (string-append #$(local-file flake
                                               #:recursive? #t) "#"
                                 (gethostname)))))))

(define (home-nix-environment-variables-service config)
  (let ((profile (home-nix-configuration-profile config)))
    `(("PATH" unquote
       (string-append (if (string-prefix? "~/" profile) "$HOME" "")
                      (if (string-prefix? "~/" profile)
                          (substring profile 1) profile) "/bin:$PATH")))))

(define-public home-nix-service-type
  (service-type (name 'home-nix)

                (extensions (list (service-extension home-profile-service-type
                                   home-nix-profile-service)

                                  (service-extension home-files-service-type
                                                     home-nix-files-service)

                                  ;; (service-extension
                                  ;; home-activation-service-type
                                  ;; home-nix-activation-service)
                                  
                                  (service-extension
                                   home-environment-variables-service-type
                                   home-nix-environment-variables-service)))

                (default-value (home-nix-configuration))

                (description
                 "Install Nix and activate a hostname-specific Nix flake into
a dedicated profile, adding the profile to PATH.")))
