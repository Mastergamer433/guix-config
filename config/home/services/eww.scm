(define-module (config home services eww)
  #:use-module (gnu home services)
  #:use-module (gnu packages window-management)
  #:use-module (config utils)
  #:use-module (gnu services configuration)
  #:use-module (guix gexp)
  #:use-module (config utils)
  #:use-module (config vars)

  #:export (home-eww-service-type home-eww-configuration))

(define (home-eww-config config)
  (let ((theme-scss
         (plain-file "theme.scss" (theme->scss %theme))))

    (computed-file
     "eww"
     (with-imported-modules
         '((guix build utils))
       #~(begin
           (use-modules (guix build utils))

           (mkdir #$output)

           (copy-recursively
            #$(service-config-directory-file)
            #$output)

           (copy-file
            #$theme-scss
            (string-append #$output "/theme.scss")))))))

(define (home-eww-files config)
  `((".config/eww" ,(home-eww-config config))))

(define home-eww-service-type
  (service-type (name 'home-eww)

                (extensions (list (service-extension home-profile-service-type
                                   (const (list eww)))

                                  (service-extension home-files-service-type
                                                     home-eww-files)))

                (default-value #f)

                (description "Configure Eww and install Eww.")))
