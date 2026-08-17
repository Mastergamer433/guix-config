(define-module (config home services xdg-desktop-portal-hyprland)
	       #:use-module (gnu)
	       #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu packages)
  #:use-module (gnu packages freedesktop)
  #:use-module (guix gexp)
	       )

(define (home-xdg-desktop-portal-hyprland-profile-service config)
  (map specification->package
       (list "xdg-desktop-portal-hyprland" "xdg-desktop-portal")))

(define (home-xdg-desktop-portal-hyprland-shepherd-service config)
  (list (shepherd-service
   (provision '(xdg-desktop-portal-hyprland))
   (requirement '(dbus))
   (documentation "Portal service for Hyprland.")
   (start
    #~(make-forkexec-constructor
       (list #$(file-append
                xdg-desktop-portal-hyprland
                "/libexec/xdg-desktop-portal-hyprland"))
       #:environment-variables
       (list "WAYLAND_DISPLAY=")
                                           #:log-file (string-append (or (getenv
                                                                   "XDG_LOG_HOME")
                                                                  (format #f
                                                                   "~a/.local/var/log"
                                                                   (getenv
                                                                    "HOME")))
                                                              "/xdg-desktop-portal-hyprland.log")))
   (stop #~(make-kill-destructor)))))

(define-public home-xdg-desktop-portal-hyprland-service-type
	       (service-type (name 'home-xdg-desktop-portal-hyprland)
			     (description "Configures and runs xdg-desktop-portal-hyprland as a Shepherd service.")
			     (default-value #f)
			     (extensions (list (service-extension home-profile-service-type
								  home-xdg-desktop-portal-hyprland-profile-service)
					       (service-extension
							home-shepherd-service-type
							home-xdg-desktop-portal-hyprland-shepherd-service)))))
