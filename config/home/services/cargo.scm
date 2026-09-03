(define-module (config home services cargo)
  #:use-module (gnu services)
  #:use-module (gnu home services)
  #:use-module (gnu packages rust)
  #:use-module (config utils)
  #:export (home-cargo-service-type))

(define (home-cargo-profile-service config)
  (list rust))

(define (home-cargo-files-service config)
  `((" .cargo/config.toml"
     ,(service-config-file "config.toml"))))

(define-public home-cargo-service-type
  (service-type
   (name 'home-cargo)

   (extensions
    (list
;     (service-extension
;      home-profile-service-type
;      home-cargo-profile-service)

     (service-extension
      home-files-service-type
      home-cargo-files-service)))

   (default-value #f)

   (description
    "Install and configure Cargo.")))
