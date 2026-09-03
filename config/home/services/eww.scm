(define-module (config home services eww)
  #:use-module (gnu home services)
  #:use-module (gnu packages wm)
  #:use-module (config utils)
  #:use-module (gnu services configuration)

  #:export (home-eww-service-type
            home-eww-configuration))

(define (home-eww-files config)
  `((" .config/eww"
     ,(service-config-directory-file))))

(define home-eww-service-type
  (service-type
   (name 'home-eww)

   (extensions
    (list
     (service-extension
      home-profile-service-type
      (const (list eww)))

     (service-extension
      home-files-service-type
      home-eww-files)))

   (default-value #f)
 

   (description
    "Configure Eww and install Eww.")))
