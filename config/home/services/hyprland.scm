(define-module (config home services hyprland)
  #:use-module (gnu home services)
  #:use-module (gnu packages window-management)
  #:use-module (gnu packages xdisorg)
  #:use-module (guix gexp)
  #:use-module (config utils)
  #:use-module (gnu services configuration)
  #:use-module (config packages hyprland)

  #:export (home-hyprland-service-type home-hyprland-configuration))

(define-configuration/no-serialization home-hyprland-configuration
                                       (config (file-like my-hypr-config)
                                        "Hyprland configuration package."))

(define (home-hyprland-files config)
  `((".config/hypr" ,(computed-file "hypr"
                                    (with-imported-modules '((guix build utils))
                                                           #~(begin
                                                               (use-modules (guix
                                                                             build
                                                                             utils))
                                                               (mkdir #$output)

                                                               (copy-recursively #$
                                                                (file-append (home-hyprland-configuration-config
                                                                              config)
                                                                 "/share/hypr")
                                                                #$output)

                                                               (copy-file #$(service-config-file
                                                                             "hyprlock.conf")
                                                                          (string-append #$output
                                                                           "/hyprlock.conf"))))))))

(define (home-hyprland-packages config)
  (list hyprland hyprlock hypridle
        (home-hyprland-configuration-config config)))

(define home-hyprland-service-type
  (service-type (name 'home-hyprland)

                (extensions (list (service-extension home-profile-service-type
                                   home-hyprland-packages)

                                  (service-extension home-files-service-type
                                                     home-hyprland-files)))

                (default-value (home-hyprland-configuration (config
                                                             my-hypr-config)))

                (description
                 "Configure Hyprland and install its required packages.")))
