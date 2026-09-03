(define-module (config utils)
  #:use-module (config vars)
  #:use-module (guix gexp)
  #:use-module (srfi srfi-1)
  #:export (service-config-file
	    service-config-directory
	    service-config-directory-file))

(define-syntax service-config-directory
  (lambda (stx)
    (syntax-case stx ()
      [(_)
       (with-syntax ([module-name
                      (datum->syntax stx
                                     (last (module-name (current-module))))])
         #'(string-append
            %config-root
            "/files/"
            (symbol->string 'module-name)))])))

(define-syntax service-config-file
  (syntax-rules ()
    ((_ file)
     (local-file
      (string-append
       (service-config-directory)
       "/"
       file)))))

(define-syntax service-config-directory-file
  (syntax-rules ()
    ((_)
     (local-file
      (service-config-directory)
      #:recursive? #t))))
