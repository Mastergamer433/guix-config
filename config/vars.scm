(define-module (config vars)
  #:use-module (guix gexp)
  #:use-module (gnu system keyboard)
  #:export (%config-root
	    %keyboard-layout
	    %theme))

(define %config-root
  (or (getenv "CONFIG_ROOT")
      (error "CONFIG_ROOT environment variable is not set")))

(define %keyboard-layout (keyboard-layout "se"))

(define %theme
  (call-with-input-file "files/themes/gruvbox-light-soft.scm"
    read))
