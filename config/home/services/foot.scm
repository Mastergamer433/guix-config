(define-module (config home services foot)
  #:use-module (gnu services)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:use-module (gnu packages terminals)
  #:use-module (config utils)
  #:export (home-foot-service-type))

(define (home-foot-profile-service config)
  (list foot))

(define (home-foot-files-service config)
  `((" .config/foot/foot.ini" ,(service-config-file "foot.ini"))))

(define-public home-foot-service-type
  (service-type (name 'home-foot)
                (extensions (list (service-extension home-profile-service-type
                                   home-foot-profile-service)

                                  (service-extension home-files-service-type
                                                     home-foot-files-service)))
                (default-value #f)
                (description "Install and configure foot.")))
