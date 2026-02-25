(in-package :stumpwm)

(defvar *config-dir* (merge-pathnames ".stumpwm.d/" (user-homedir-pathname)))
;; Load base system
(load (merge-pathnames "base.lisp" *config-directory*))

;; Host-specific config loading
(let* ((host (machine-instance))
       (hosts-dir (merge-pathnames "hosts/" *config-directory*))
       (host-file (merge-pathnames
                   (format nil "~A.lisp" host)
                   hosts-dir)))

  (if (probe-file host-file)
      (load host-file)
      (message "No host config found for ~A" host)))

(let ((quicklisp-init
       (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))
(ql:quickload :slynk)
