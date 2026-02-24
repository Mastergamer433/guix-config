(define-module (config home services kmonad)
  #:use-module (gnu packages)
  #:use-module (gnu packages linux)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (guix gexp)
  #:export (home-kmonad-service-type))

;; Optional: install kmonad package for this profile
(define (home-kmonad-profile-service config)
  (map specification->package
       (list "kmonad")))

;; Shepherd service definition
(define (home-kmonad-shepherd-service config)
  (list (shepherd-service (requirement '())
                          (provision '(kmonad))
                          (stop #~(make-kill-destructor))
                          (start #~(make-forkexec-constructor
                                    ;; Command to run kmonad with your config
                                    (list "kmonad"
                                          (string-append (getenv "HOME")
                                           "/.config/kmonad/kmonad.kbd"))
                                    #:log-file (string-append (or (getenv
                                                                   "XDG_LOG_HOME")
                                                                  (format #f
                                                                   "~a/.local/var/log"
                                                                   (getenv
                                                                    "HOME")))
                                                              "/kmonad.log")
                                    #:environment-variables (append (list
                                                                     "DISPLAY=:0" ;adjust for your graphical session
                                                                     "XAUTHORITY=/home/user/.Xauthority")
                                                                    (default-environment-variables)))))))

;; Optionally, you could add XDG configuration files here, if needed
(define (home-kmonad-xdg-configuration-service config)
  '())

;; Define the complete service type
(define-public home-kmonad-service-type
  (service-type (name 'home-kmonad)
                (extensions (list (service-extension home-profile-service-type
                                   home-kmonad-profile-service)
                                  (service-extension
                                   home-shepherd-service-type
                                   home-kmonad-shepherd-service)
                                  (service-extension
                                   home-xdg-configuration-files-service-type
                                   home-kmonad-xdg-configuration-service)))
                (default-value #f)
                (description
                 "Configures and runs kmonad as a Shepherd service.")))
