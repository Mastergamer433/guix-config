(setq my/config-options
      '((ui
	 :enabled t
	 :font "Fira Code")
	(completion
	 :enabled t
	 :in-buffer t)
        (terms
	 :eat t)
	(help
	 :enabled t)
        (programming
	 :enabled t
	 (rust
	  :enabled t)
	 (lisp
	  :enabled t)
	 (go
	  :enabled t)
	 (haskell
	  :enabled t)
	 (zig
	  :enabled t)
	 (magit
	  :enabled t)
	 (http
	  :enabled t))
	(dired :enabled t)
        (org :enabled t :org-dir "~/org" :org-roam-dir "~/notes")))

(my/load-modules-recursive nil my/config-options)
(use-package move-text
  :bind (("M-p" . move-text-up)
	 ("M-n" . move-text-down)))
(defvar emacs-config-directory "~/config/files/.emacs.d")

(defun my/get-emacs-hosts ()
; regex matches . and .. but not anything containing . as to not remove dotfiles
  (mapcar #'file-name-sans-extension (directory-files (file-name-concat emacs-config-directory "hosts/") nil "^[^.].*\\|^\\.[^.].*")))

(my/get-emacs-hosts)
(defun my/get-emacs-host-file (host)
  (file-name-concat emacs-config-directory "hosts/" (concat host ".el")))

(defun my/jump-to-emacs-host (host)
  (interactive (list (completing-read "Host: " (my/get-emacs-hosts))))
  (my/get-emacs-host-file host))

(defun my/jump-to-current-emacs-host ()
  (interactive)
  (find-file (my/get-emacs-host-file (system-name))))

(defun my/find-file-emacs-module ()
  (interactive)
  (progn
    (let ((default-directory (file-name-concat emacs-config-directory "modules/")))
      (call-interactively 'find-file))))

;(use-package org-novel
;  :load-path "~/Projects/org-novel"
;  :init
;  (setq org-novel-directory "~/book-project/"))
