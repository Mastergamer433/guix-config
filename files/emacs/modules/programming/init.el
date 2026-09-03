(setq module-schema '(:enabled))

(defmodule (:enabled)
	   (when (plist-get cfg :enabled)
	     (use-package direnv
	       :ensure t
	       :bind (("C-c d d" . direnv-mode)
		      ("C-c d a" . direnv-allow)))
	     (global-unset-key (kbd "C-c i"))

	     (use-package eglot
	       :ensure nil
	       :hook ((rust-mode . eglot-ensure)
		      (before-save . eglot-format-buffer))
	       :bind (("C-c i i" . eglot-find-implementation)
		      ("C-c i e" . eglot)
		      ("C-c i k" . eglot-shutdown-all)
		      ("C-c i r" . eglot-rename)
		      ("C-c i x" . eglot-reconnect)
		      ("C-c i a" . eglot-code-actions)
		      ("C-c i m" . eglot-menu)
		      ("C-c i f" . eglot-format-buffer)
		      ("C-c i h" . eglot-inlay-hints-mode))
	       :init
	       (setq eglot-autoshutdown t
		     eglot-confirm-server-edits nil
		     eglot-report-progress t
		     eglot-extend-to-xref t
		     eglot-autoreconnect t)
	       :config
	       (setq-default eglot-workspace-configuration
			     '(:rust-analyzer (:check (:command "clippy")
						      :cargo (:sysroot "discover"
								       :features "all"
								       :buildScripts (:enable t))
						      :diagnostics (:disabled ["macro-error"])
						      :procMacro (:enable t))))

	       (add-hook 'eglot-managed-mode-hook
			 (lambda ()
			   ;; Show flymake diagnostics first.
			   (setq eldoc-documentation-functions
				 (cons #'flymake-eldoc-function
				       (remove #'flymake-eldoc-function eldoc-documentation-functions)))
			   ;; Show all eldoc feedback.
			   (setq eldoc-documentation-strategy #'eldoc-documentation-compose)
			   (add-hook 'before-save-hook
				     #'eglot-format-buffer
				     nil t)))

	       )
	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     ;; (use-package eglot				     ;;
	     ;;   :hook ((rust-mode . eglot-ensure))		     ;;
	     ;;   :config					     ;;
	     ;;   ;; Optional: Auto-format on save		     ;;
	     ;;   (add-hook 'eglot-managed-mode-hook		     ;;
	     ;; 		 (lambda ()			     ;;
	     ;; 		   (add-hook 'before-save-hook	     ;;
	     ;; 			     #'eglot-format-buffer   ;;
	     ;; 			     nil t))))		     ;;
	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
