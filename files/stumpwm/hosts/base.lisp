(in-package :stumpwm)

;;;; ------------------------------------------------------------------
;;;; Core paths

(defparameter *module-root*
  (merge-pathnames "modules/" *config-directory*))

(defparameter *config-options* nil
  "Holds validated options for all modules.")

;;;; ------------------------------------------------------------------
;;;; Utilities

(defun module-path-to-string (path)
  "Join PATH list into string. '(\"org\" \"note-taking\") → \"org/note-taking\""
  (format nil "~{~A~^/~}" path))

(defun validate-config (cfg allowed)
  "Ensure CFG is a plist whose keys are all in ALLOWED."
  (unless (and (listp cfg)
               (keywordp (first cfg)))
    (error "Config is not a plist: ~S" cfg))
  (loop for (k v) on cfg by #'cddr
        unless (member k allowed)
        do (error "Unknown option ~S (allowed: ~S)" k allowed)))

;;;; ------------------------------------------------------------------
;;;; Module loader

(defun load-modules-recursive (path cfg)
  "Recursively load modules starting at PATH using CFG.

CFG format example:
((ui :enabled t)
 (org
   (note-taking :enabled t)))"
  (let* ((module-dir
          (merge-pathnames
           (module-path-to-string path)
           *module-root*))
         (init-file
          (merge-pathnames "init.lisp" module-dir)))

    (message "Checking for module in: ~A" module-dir)

    ;; Split into local options + submodules
    (let ((local-options '())
          (submodules '()))
      (dolist (entry cfg)
        (if (and (consp entry)
                 (symbolp (car entry)))
            (push entry submodules)
            (push entry local-options)))

      (setf local-options (nreverse local-options)
            submodules (nreverse submodules))

      ;; Load current module
      (when (and path
                 (probe-file init-file))
        (let ((*module-schema* nil)
              (*module-setup-fn* nil))

          (load init-file)

          (when *module-schema*
            (validate-config local-options *module-schema*))

          (when *module-setup-fn*
            (funcall *module-setup-fn* local-options))))

      ;; Recurse into submodules
      (dolist (subcfg submodules)
        (let ((key (car subcfg))
              (subcfg-body (cdr subcfg)))
          (load-modules-recursive
           (append path (list (symbol-name key)))
           subcfg-body))))))

;;;; ------------------------------------------------------------------
;;;; defmodule macro

(defmacro defmodule (schema &body body)
  "Define a module with SCHEMA and setup BODY.
SCHEMA is a list of allowed keywords.
BODY is a function of a single argument CFG, the options plist."
  `(progn
     (setf *module-schema* ',schema)
     (setf *module-setup-fn*
           (lambda (cfg)
             ,@body))))
