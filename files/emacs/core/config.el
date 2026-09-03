;;; core/config.el -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'seq)


(defvar my/config nil
  "Global nested Emacs configuration.")

(defvar my/module-root
  (expand-file-name "modules" user-emacs-directory)
  "Root directory containing Emacs modules.")


;;; =========================
;;; CONFIGURATION LOOKUP
;;; =========================

(defun my/config-section (path)
  "Return configuration section at PATH.

PATH is a list of symbols.

For example:

  (my/config-section '(programming rust))

returns the configuration for the Rust subsection of
the programming configuration."
  (let ((config my/config))
    (dolist (name path)
      (setq config
            (cdr (assq name config))))
    config))


(defun my/config-get (path key &optional default)
  "Return KEY from configuration at PATH.

PATH is a list of symbols.

For example:

  (my/config-get '(org) :org-dir)

or:

  (my/config-get '(programming rust) :enabled)"
  (let ((config (my/config-section path)))
    (if (plist-member config key)
        (plist-get config key)
      default)))


(defun my/config-enabled-p (path)
  "Return whether configuration at PATH is enabled."
  (my/config-get path :enabled t))


;;; =========================
;;; MODULE CONFIG ACCESSORS
;;; =========================

(defun my/module-config-function-name (path)
  "Return config accessor function name for PATH."
  (intern
   (concat
    "my/"
    (mapconcat #'symbol-name path "-")
    "-config")))


(defmacro my/defmodule-config (&rest path)
  "Define a config accessor for module PATH.

For example:

  (my/defmodule-config org)

defines:

  my/org-config

And:

  (my/defmodule-config programming rust)

defines:

  my/programming-rust-config

The generated function accepts a keyword and optional default:

  (my/org-config :org-dir)
  (my/org-config :org-dir \"~/org\")"
  (let ((function-name
         (my/module-config-function-name path)))
    `(defun ,function-name (key &optional default)
       ,(format "Get KEY from %s module configuration."
                (mapconcat #'symbol-name path "/"))
       (my/config-get ',path key default))))


;;; =========================
;;; MODULE PATHS
;;; =========================

(defun my/module-path-to-directory (path)
  "Return filesystem directory corresponding to module PATH."
  (expand-file-name
   (mapconcat #'symbol-name path "/")
   my/module-root))


(defun my/module-path-to-file (path)
  "Return init file corresponding to module PATH."
  (expand-file-name
   "init.el"
   (my/module-path-to-directory path)))


(defun my/module-exists-p (path)
  "Return non-nil if module PATH exists."
  (file-exists-p
   (my/module-path-to-file path)))


;;; =========================
;;; MODULE CONFIGURATION TREE
;;; =========================

(defun my/config-module-entries (config)
  "Return child module entries from CONFIG.

A module entry is a list whose first element is a symbol
and whose remaining elements contain its configuration."
  (seq-filter
   (lambda (entry)
     (and (consp entry)
          (symbolp (car entry))))
   config))


(defun my/config-module-name (entry)
  "Return module name from configuration ENTRY."
  (car entry))


(defun my/config-module-body (entry)
  "Return module configuration from ENTRY."
  (cdr entry))


(defun my/config-module-path (parent entry)
  "Return full module path for ENTRY under PARENT."
  (append parent
          (list (my/config-module-name entry)))


;;; =========================
;;; MODULE LOADING
;;; =========================

(defun my/load-module (path)
  "Load module at PATH.

PATH is a list of symbols.

For example:

  (my/load-module '(org))

loads:

  modules/org/init.el

while:

  (my/load-module '(programming rust))

loads:

  modules/programming/rust/init.el

if that file exists."
  (let ((file (my/module-path-to-file path)))
    (when (file-exists-p file)
      (load file nil 'nomessage))))


(defun my/load-module-children (path config)
  "Load child modules configured under PATH."
  (dolist (entry (my/config-module-entries config))
    (let ((child-path
           (my/config-module-path path entry)))
      (my/load-module child-path)
      (my/load-module-children
       child-path
       (my/config-module-body entry)))))


(defun my/load-modules ()
  "Load all modules described by `my/config`."
  (dolist (entry (my/config-module-entries my/config))
    (let ((path
           (my/config-module-path nil entry)))
      (my/load-module path)
      (my/load-module-children
       path
       (my/config-module-body entry)))))


;;; =========================
;;; RELOADING
;;; =========================

(defun my/reload-module (path)
  "Reload module at PATH.

PATH is a list of symbols.

For example:

  (my/reload-module '(org))

or:

  (my/reload-module '(programming rust))."
  (interactive
   (list
    (let ((name
           (completing-read
            "Module: "
            (my/module-names))))
      (my/module-name-to-path name))))

  (let ((file (my/module-path-to-file path)))
    (unless (file-exists-p file)
      (user-error "Module does not exist: %s"
                  (mapconcat #'symbol-name path "/")))

    (load file nil 'nomessage)
    (message "Reloaded module: %s"
             (mapconcat #'symbol-name path "/"))))


(defun my/config-module-paths (&optional config parent)
  "Return all configured module paths."
  (let ((config (or config my/config))
        (parent (or parent nil))
        paths)

    (dolist (entry (my/config-module-entries config))
      (let ((path
             (my/config-module-path parent entry)))
        (push path paths)
        (setq paths
              (append
               (nreverse
                (my/config-module-paths
                 (my/config-module-body entry)
                 path))
               paths))))

    (nreverse paths)))


(defun my/module-name (path)
  "Convert module PATH to display name."
  (mapconcat #'symbol-name path "/"))


(defun my/module-names ()
  "Return names of all configured modules."
  (mapcar #'my/module-name
          (my/config-module-paths)))


(defun my/module-name-to-path (name)
  "Convert module NAME into a module path."
  (mapcar #'intern
          (split-string name "/" t)))


;;; =========================
;;; INITIALIZATION
;;; =========================

(defun my/configure-modules (config)
  "Set global configuration and load configured modules."
  (setq my/config config)
  (my/load-modules))
