(define-module (config systems base-system)
	       #:use-modules (gnu)
	       #:use-modules (guix)
	       #:export (base-system))

(define base-system
  (operating-system
    (host-name "base-system")
    (timezone "Etc/UTC")
    (locale "en_US.utf8")
    (keyboard-layout (keyboard-layout "us" "altgr-intl"))
