(define-module (config home services spotifyd)
  #:use-module (gnu packages)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (guix gexp)
  #:export (home-spotifyd-service-type))

;; Optional: install kmonad package for this profile
(define (home-spotifyd-profile-service config)
  (map specification->package
       (list "spotifyd")))

;; Shepherd service definition
(define (home-spotifyd-shepherd-service config)
    (display "spotifyd shepherd service called\n" (current-error-port))
  (list (shepherd-service (requirement '())
                          (provision '(spotifyd))
                          (stop #~(make-kill-destructor))
                          (start #~(make-forkexec-constructor
                                    ;; Command to run kmonad with your config
                                    (list "spotifyd" "--no-daemon")
                                    #:log-file (string-append (or (getenv
                                                                   "XDG_LOG_HOME")
                                                                  (format #f
                                                                   "~a/.local/var/log"
                                                                   (getenv
                                                                    "HOME")))
                                                              "/spotifyd.log"))))))

;; Define the complete service type
(define-public home-spotifyd-service-type
  (service-type (name 'home-spotifyd)
                (extensions (list (service-extension home-profile-service-type
                                   home-spotifyd-profile-service)
                                  (service-extension
                                   home-shepherd-service-type
                                   home-spotifyd-shepherd-service)))
                (default-value #f)
                (description
                 "Configures and runs spotifyd as a Shepherd service.")))
