(In-package :stumpwm)

(stumpwm:add-to-load-path "~/.guix-home/profile/share/common-lisp/sbcl/slynk")

(defparameter *config-directory* (merge-pathnames ".stumpwm.d/" (user-homedir-pathname)))

;; Load base system
(load (merge-pathnames "hosts/base.lisp" *config-directory*))

;; Host-specific config loading
(let* ((host (machine-instance))
       (hosts-dir (merge-pathnames "hosts/" *config-directory*))
       (host-file (merge-pathnames
                   (format nil "~A.lisp" host)
                   hosts-dir)))

  (if (probe-file host-file)
      (load host-file)
      (message "No host config found for ~A" host)))
(require :slynk)
