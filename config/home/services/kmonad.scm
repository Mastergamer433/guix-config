(define-module (config home services kmonad)
  #:use-module (gnu packages)
  #:use-module (gnu packages haskell-apps)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (guix gexp)
  #:use-module (config utils)
  #:export (home-kmonad-service-type))

(define (home-kmonad-profile-service config)
  (list kmonad))

(define (home-kmonad-files-service config)
  `((".config/kmonad/kmonad.kbd" ,(service-config-file "kmonad.kbd"))))

(define (home-kmonad-shepherd-service config)
  (list (shepherd-service (requirement '())
                          (provision '(kmonad))
                          (stop #~(make-kill-destructor))
                          (start #~(make-forkexec-constructor (list #$(file-append
                                                                       kmonad
                                                                       "/bin/kmonad")
                                                                    (string-append
                                                                     (getenv
                                                                      "HOME")
                                                                     "/.config/kmonad/kmonad.kbd"))
                                                              #:log-file (string-append
                                                                          (or (getenv
                                                                               "XDG_LOG_HOME")

                                                                              
                                                                              (format
                                                                               #f
                                                                               "~a/.local/var/log"

                                                                               
                                                                               (getenv
                                                                                "HOME")))
                                                                          "/kmonad.log")
                                                              #:environment-variables
                                                              (append (list
                                                                       "DISPLAY=:0"
                                                                       "XAUTHORITY=/home/user/.Xauthority")
                                                                      (default-environment-variables)))))))

(define-public home-kmonad-service-type
  (service-type (name 'home-kmonad)

                (extensions (list (service-extension home-profile-service-type
                                   home-kmonad-profile-service)

                                  (service-extension home-files-service-type
                                   home-kmonad-files-service)

                                  (service-extension
                                   home-shepherd-service-type
                                   home-kmonad-shepherd-service)))

                (default-value #f)

                (description
                 "Install and run kmonad with the user's kmonad configuration.")))
