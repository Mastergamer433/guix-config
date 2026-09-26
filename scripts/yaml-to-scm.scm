#!/usr/bin/env -S guix shell guile guile-yamlpp -- guile -s
!#

(use-modules
  (yamlpp)
  (ice-9 pretty-print)
  (ice-9 textual-ports))

(define (main)
  (let ((args (cdr (command-line))))
    (unless (= (length args) 2)
      (format (current-error-port)
              "Usage: yaml-to-scm.scm INPUT.yaml OUTPUT.scm~%")
      (exit 1))

    (let* ((input (car args))
           (output (cadr args))
           (yaml
            (call-with-input-file input
              (lambda (port)
                (get-string-all port))))
           (data (yaml-load yaml)))

      (call-with-output-file output
        (lambda (port)
          (pretty-print data port))))))

(main)
