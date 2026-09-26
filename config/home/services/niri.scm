(define-module (config home services niri)
  #:use-module (gnu home services)
  #:use-module (gnu packages window-management)
  #:use-module (gnu services configuration)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages guile)
  #:use-module (config utils)
  #:use-module (config packages go-xyz)

  #:export (home-niri-service-type
            home-niri-configuration))


(define-configuration/no-serialization home-niri-configuration
                                       (package (package niri)
                                        "Niri package.")

                                       (extra-packages (list '())
                                        "Additional packages.")

                                       (data (list '())
                                        "Niri configuration data."))


(define (scm->json-file name data)
  (computed-file
   name
   (with-extensions
       (list guile-json-4)
     #~(begin
         (use-modules (json))

         (call-with-output-file #$output
           (lambda (port)
             (scm->json '#$data port)))))))


(define (home-niri-config config)
  (let ((json (scm->json-file
               "niri.json"
               (home-niri-configuration-data config))))

    (computed-file
     "niri"
     (with-imported-modules '((guix build utils))
       #~(begin
           (use-modules (guix build utils))

           (mkdir #$output)

           ;; Copy everything from files/niri.
           (copy-recursively #$(service-config-directory-file)
                             #$output)

           ;; Render niri.tpl to config.kdl.
           (let ((input
                  (open-input-file #$json))
                 (output
                  (open-output-file
                   (string-append #$output "/config.kdl"))))

             (parameterize ((current-input-port input)
                            (current-output-port output))
               (invoke #$(file-append go-github-com-bluebrown-go-template-cli "/bin/tpl")
                       "--file"
                       #$(service-config-file "niri.tpl")
		       "--name"
		       "niri"))

             (close-port input)
             (close-port output))

           ;; niri.tpl is only the source template and should not
           ;; be installed in the resulting configuration directory.
           (delete-file
            (string-append #$output "/niri.tpl")))))))


(define (home-niri-files config)
  `((".config/niri"
     ,(home-niri-config config))))


(define (home-niri-packages config)
  (append
   (list
    (home-niri-configuration-package config)
    go-github-com-bluebrown-go-template-cli)
   (home-niri-configuration-extra-packages config)))


(define home-niri-service-type
  (service-type
   (name 'home-niri)

   (extensions
    (list
     (service-extension home-profile-service-type
                        home-niri-packages)

     (service-extension home-files-service-type
                        home-niri-files)))

   (default-value
    (home-niri-configuration
     (package niri)
     (extra-packages '())
     (data '())))

   (description
    "Configure Niri and install its required packages.")))
