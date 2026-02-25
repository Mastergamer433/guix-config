(define-module (config home harry-potter)
  #:use-module (gnu home)
  #:use-module (config home base-home)
  #:export (%harry-potter-home))

(define %harry-potter-home
  (home-environment
    (inherit %base-home)))
