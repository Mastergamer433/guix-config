(setq module-schema '(:enabled))

(defmodule (:enabled)
	   (when (plist-get cfg :enabled)
	     (use-package eglot
	       :hook ((rust-mode . eglot-ensure))
	       :config
	       ;; Optional: Auto-format on save
	       (add-hook 'eglot-managed-mode-hook
			 (lambda ()
			   (add-hook 'before-save-hook
				     #'eglot-format-buffer
				     nil t))))
	     (use-package avy
	       :ensure t
	       :bind (("C-:" . avy-goto-char)
		      ("C-'" . avy-goto-char-2)
		      ("M-g f" . avy-goto-line)
		      ("M-g w" . avy-goto-word-1))
	       :custom
	       (avy-background t)          ;; dim background during selection
	       (avy-style 'at-full)        ;; show full path hints
	       (avy-all-windows t)         ;; search across all visible windows
	       (avy-timeout-seconds 0.3))  ;; quick hint timeout
	     ))
