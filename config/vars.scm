(define-module (config vars)
  #:use-module (guix gexp)
  #:export (%config-root))

(define %config-root
  (or (getenv "CONFIG_ROOT")
      (error "CONFIG_ROOT environment variable is not set")))
