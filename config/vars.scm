(define-module (config vars)
  #:use-module (guix gexp)
  #:export (%config-root))

(define %config-root
 (getenv "GUIX_CONFIG_ROOT"))
