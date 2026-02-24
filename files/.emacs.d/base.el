(defvar my/module-root (expand-file-name "modules" user-emacs-directory))
(defvar my/config-options nil
  "Holds validated options for all modules.")

(defun my/module-path-to-string (path)
  "Join PATH list into string, e.g. '(org note-taking) -> 'org/note-taking'."
  (mapconcat #'identity path "/"))
(defun my/validate-config (cfg allowed)
  "Ensure CFG is a plist whose keyword keys are all in ALLOWED."
  (unless (and (listp cfg) (keywordp (car cfg)))
    (error "Config is not a plist: %S" cfg))
  (cl-loop for (k v) on cfg by #'cddr
           unless (memq k allowed)
           do (error "Unknown option %S (allowed: %S)" k allowed)))

(defun my/validate-config (cfg allowed)
  "Ensure CFG is a plist whose keyword keys are all in ALLOWED."
  (unless (and (listp cfg) (keywordp (car cfg)))
    (error "Config is not a plist: %S" cfg))
  (let ((plist cfg))
    (while plist
      (let ((k (car plist)))
        (unless (memq k allowed)
          (error "Unknown option %S (allowed: %S)" k allowed)))
      (setq plist (cddr plist)))))
(defun my/load-modules-recursive (path cfg)
  "Recursively load modules starting at PATH using CFG.
CFG is an alist at this level: ((ui :enabled t ...) ...)."
  (let* ((module-dir (expand-file-name (my/module-path-to-string path)
                                       my/module-root))
         (init-file (expand-file-name "init.el" module-dir)))
    (message "Checking for module in: %s" module-dir)
    ;; Split cfg into local options (plist) and submodules (list of lists)
    (let ((local-options nil)
          (submodules nil))
      (dolist (entry cfg)
        (if (and (consp entry) (symbolp (car entry)))
            (push entry submodules)
          (push entry local-options)))
      (setq local-options (nreverse local-options)
            submodules (nreverse submodules))
      ;; Load current module
      (when (and path (file-exists-p init-file))
        (let ((module-schema nil)
              (module-setup-fn nil))
          (load init-file)
          (when module-schema
            (my/validate-config local-options module-schema))
          (when module-setup-fn
            (funcall module-setup-fn local-options))))
      ;; Recurse into submodules
      (dolist (subcfg submodules)
        (let ((key (car subcfg))
              (subcfg-body (cdr subcfg)))
          (my/load-modules-recursive
           (append path (list (symbol-name key)))
           subcfg-body))))))

(defmacro defmodule (schema &rest body)
  `(progn
     (setq module-schema ',schema)
     (setq module-setup-fn (lambda (cfg) ,@body))))

(defvar bootstrap-version)
(let ((bootstrap-file
      (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
        "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
        'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

(setq backup-directory-alist `(("." . ,(expand-file-name "tmp/backups/" user-emacs-directory))))

;; auto-save-mode doesn't create the path automatically!
(make-directory (expand-file-name "tmp/auto-saves/" user-emacs-directory) t)

(setq auto-save-list-file-prefix (expand-file-name "tmp/auto-saves/sessions/" user-emacs-directory)
      auto-save-file-name-transforms `((".*" ,(expand-file-name "tmp/auto-saves/" user-emacs-directory) t)))

(setq create-lockfiles nil)

(setq projectile-known-projects-file (expand-file-name "tmp/projectile-bookmarks.eld" user-emacs-directory)
      lsp-session-file (expand-file-name "tmp/.lsp-session-v1" user-emacs-directory))

(use-package no-littering)
