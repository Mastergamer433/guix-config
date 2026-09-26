(define-module (config home services foot)
  #:use-module (gnu services)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:use-module (gnu packages terminals)
  #:use-module (config utils)
  #:use-module (config vars)
  #:export (home-foot-service-type))

(define (home-foot-profile-service config)
  (list foot))

(define (theme->foot-colors theme)
  (define (color name)
    (cdr (assoc name theme)))

  (string-join
   (list
    "[colors-dark]"
    "alpha=1.0"
    ""
    (format #f "foreground=~a" (color "base05"))
    (format #f "background=~a" (color "base00"))
    ""
    (format #f "regular0=~a" (color "base00"))
    (format #f "regular1=~a" (color "base08"))
    (format #f "regular2=~a" (color "base0B"))
    (format #f "regular3=~a" (color "base0A"))
    (format #f "regular4=~a" (color "base0D"))
    (format #f "regular5=~a" (color "base0E"))
    (format #f "regular6=~a" (color "base0C"))
    (format #f "regular7=~a" (color "base05"))
    ""
    (format #f "bright0=~a" (color "base03"))
    (format #f "bright1=~a" (color "base08"))
    (format #f "bright2=~a" (color "base0B"))
    (format #f "bright3=~a" (color "base0A"))
    (format #f "bright4=~a" (color "base0D"))
    (format #f "bright5=~a" (color "base0E"))
    (format #f "bright6=~a" (color "base0C"))
    (format #f "bright7=~a" (color "base07")))
   "\n"))

(define (foot-colors-file theme)
  (plain-file
   "colors.ini"
   (theme->foot-colors theme)))

(define (home-foot-config theme)
  (let ((colors (foot-colors-file theme)))
    (computed-file
     "foot"
     (with-imported-modules
         '((guix build utils))
       #~(begin
           (use-modules (guix build utils))

           (mkdir #$output)

	   (copy-recursively
            #$(service-config-directory-file)
            #$output)

           (copy-file
            #$colors
            (string-append #$output "/colors.ini")))))))

(define (home-foot-files-service config)
  `((".config/foot" ,(home-foot-config %theme))))

(define-public home-foot-service-type
  (service-type (name 'home-foot)
                (extensions (list (service-extension home-profile-service-type
                                   home-foot-profile-service)

                                  (service-extension home-files-service-type
                                                     home-foot-files-service)))
                (default-value #f)
                (description "Install and configure foot.")))
