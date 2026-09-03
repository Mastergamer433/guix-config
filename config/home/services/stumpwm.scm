(define-module (config home services stumpwm)
  #:use-module (gnu services)
  #:use-module (gnu home services)
  #:use-module (config utils)
  #:use-module (gnu packages wm)
  #:export (home-stumpwm-service-type))

(define (home-stumpwm-profile-service config)
  (list stumpwm))

(define (home-stumpwm-files-service config)
  `((" .stumpwm.d"
     ,(service-config-directory-file))))

(define-public home-stumpwm-service-type
  (service-type
   (name 'home-stumpwm)

   (extensions
    (list
     (service-extension
      home-profile-service-type
      home-stumpwm-profile-service)

     (service-extension
      home-files-service-type
      home-stumpwm-files-service)))

   (default-value #f)

   (description
    "Install and configure StumpWM.")))
