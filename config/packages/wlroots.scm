(define-module (config packages wlroots)
  #:use-module (guix packages)
  #:use-module (gnu packages wm)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix utils)
  #:export (wlroots-with-x11))

(define wlroots-with-x11
  (package
    (inherit wlroots)
    (arguments
     (substitute-keyword-arguments (package-arguments wlroots)
       ((#:configure-flags flags)
        #~(cons "-Dx11-backend=enabled"
                #$flags))))))
