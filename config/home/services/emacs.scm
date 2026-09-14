(define-module (config home services emacs)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (guix gexp)
  #:use-module (config packages emacs)
  #:use-module (gnu packages imagemagick)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages emacs)
  #:use-module (config utils)
  #:export (home-emacs-service-type))

(define (home-emacs-profile-service config)
  (list emacs-pgtk imagemagick ripgrep))
(define (home-emacs-files-service config)
  (format #t "CONFIG DIR = ~a~%"
          (service-config-directory-file))
  `(("TEST" ,(plain-file "test-emacs" "hello"))(".emacs.d" ,(service-config-directory-file))))
;; (define (home-emacs-files-service config)
;;   `((".emacs.d" ,(service-config-directory-file))))

(define (home-emacs-shepherd-service config)
  (list (shepherd-service (requirement '())
                          (provision '(emacs))
                          (stop #~(make-kill-destructor))
                          (start #~(make-forkexec-constructor (list "emacs"
                                                               "--fg-daemon")
                                                              #:log-file (string-append
                                                                          (or (getenv
                                                                               "XDG_LOG_HOME")
                                                                              
                                                                              (format
                                                                               #f
                                                                               "~a/.local/var/log"
                                                                               
                                                                               (getenv
                                                                                "HOME")))
                                                                          "/emacs.log"))))))

(define-public home-emacs-service-type
  (service-type (name 'home-emacs)

                (extensions (list (service-extension home-profile-service-type
                                   home-emacs-profile-service)

                                  (service-extension home-files-service-type
                                                     home-emacs-files-service)

                                  (service-extension
                                   home-shepherd-service-type
                                   home-emacs-shepherd-service)))

                (default-value #f)

                (description "Install, configure, and run the Emacs daemon.")))
