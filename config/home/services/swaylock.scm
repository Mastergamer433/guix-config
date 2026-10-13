(define-module (config home services swaylock)
  #:use-module (gnu packages window-management)
  #:use-module (gnu home services)
  #:use-module (gnu services configuration)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (guix packages)
  #:export (swaylock-configuration
            swaylock-configuration?
            swaylock-configuration-options
            swaylock-configuration-flags
            home-swaylock-service-type))

(define-configuration/no-serialization swaylock-configuration
  (package
   (package swaylock)
   "The swaylock package to install.")
  (options
   (alist '())
   "An association list of swaylock option names and values.")
  (flags
   (list '())
   "A list of swaylock flags that take no argument."))

(define (swaylock-configuration->file config)
  (plain-file
   "swaylock-config"
   (string-append
    (string-join
     (append
      (map (lambda (option)
             (format #f "~a=~a"
                     (car option)
                     (cdr option)))
           (swaylock-configuration-options config))
      (map (lambda (flag)
             (symbol->string flag))
           (swaylock-configuration-flags config)))
     "\n")
    "\n")))

(define (swaylock-configuration-files config)
  `((".config/swaylock/config"
     ,(swaylock-configuration->file config))))

(define home-swaylock-service-type
  (service-type
   (name 'home-swaylock)
   (extensions
    (list
     (service-extension
      home-files-service-type
      swaylock-configuration-files)
     (service-extension
 home-profile-service-type
 (lambda (config)
   (list (swaylock-configuration-package config))))))
   (default-value (swaylock-configuration))
   (description
    "Configure swaylock and install its package.")))
