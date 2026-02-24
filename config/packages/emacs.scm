(define-module (config packages emacs)
  #:use-module (guix packages)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages imagemagick)
  #:export (emacs-with-imagemagick))

(define-public emacs-with-imagemagick
  (package
    (inherit emacs)
    ;; Add ImageMagick to inputs
    (inputs (cons `("imagemagick" ,imagemagick)
                  (package-inputs emacs)))
    ;; Modify arguments to append "--with-imagemagick"
    (arguments
     (let ((args (package-arguments emacs)))
       (map (lambda (arg)
              (if (and (pair? arg)
                       (eq? (car arg)
                            '#:configure-flags))
                  ;; Append to existing configure flags
                  (cons '#:configure-flags
                        (append (cdr arg)
                                '("--with-imagemagick"))) arg)) args)))))
