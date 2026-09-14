(define-module (config home services bin)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:use-module (config utils)
  #:export (home-bin-configuration home-bin-service-type))

(define-configuration/no-serialization home-bin-configuration
                                       (programs (list '())
                                        "Names of programs from files/bin/ to install into ~/.bin.")

                                       (packages (list '())
                                        "Packages whose executables should be exposed in ~/.bin."))

(define (home-bin-files-service config)
  (map (lambda (program)
         `(,(string-append ".bin/" program) ,(service-config-file program)))
       (home-bin-configuration-programs config)))

(define (home-bin-activation-service config)
  (let ((packages (home-bin-configuration-packages config)))
    #~(begin
        (use-modules (guix build utils))

        (let ((bin-directory (string-append (getenv "HOME") "/.bin")))
          (mkdir-p bin-directory)

          #$@(map (lambda (package
                            )
                    #~(begin
                        (for-each (lambda (file)
                                    (let ((source (string-append #$(file-append
                                                                    package
                                                                    "/bin/")
                                                                 file))
                                          (target (string-append bin-directory
                                                   "/" file)))
                                      (when (file-exists? source)
					                (copy-file source target)
                (chmod target #o755))))
                            
                                  (scandir #$(file-append package "/bin")
                                           (lambda (file)
                                             (not (member file
                                                          '("." ".."))))))))
                  packages)))))

(define-public home-bin-service-type
  (service-type (name 'home-bin)

                (extensions (list (service-extension home-files-service-type
                                                     home-bin-files-service)

                                  (service-extension
                                   home-activation-service-type
                                   home-bin-activation-service)))

                (default-value (home-bin-configuration))

                (description
                 "Install scripts and expose package executables in ~/.bin.")))
