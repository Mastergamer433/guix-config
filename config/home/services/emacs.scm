(define-module (config home services emacs)
  #:use-module (gnu packages)
  #:use-module (gnu packages linux)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (guix gexp)
  #:export (home-emacs-service-type))

;; Optional: install kmonad package for this profile
(define (home-emacs-profile-service config)
  (list emacs-with-imagemagick font-fira-code))

;; Shepherd service definition
(define (home-emacs-shepherd-service config)
  (list (shepherd-service (requirement '())
                          (provision '(kmonad))
                          (stop #~(make-kill-destructor))
                          (start #~(make-forkexec-constructor
                                    ;; Command to run kmonad with your config
                                    (list "emacs"))))))

;; Define the complete service type
(define-public home-emacs-service-type
  (service-type (name 'home-kmonad)
                (extensions (list (service-extension home-profile-service-type
                                   home-emacs-profile-service)
                                  (service-extension
                                   home-shepherd-service-type
                                   home-emacs-shepherd-service)))
                (default-value #f)
                (description "Runs emacs as a Shepherd service.")))
