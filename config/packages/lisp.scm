(define-module (config packages lisp)
  #:use-module (guix packages)
  #:use-module (gnu packages lisp)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (jpm-1.2.0))

(define jpm-1.2.0
  (package
    (inherit jpm)
    (name "jpm-1.2.0")
    (version "1.2.0")))
