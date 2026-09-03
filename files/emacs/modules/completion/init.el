(defun keo/minibuffer-backward-kill (arg)
  (interactive "p")
  (cond
   ;; When minibuffer has ~/
   ((and minibuffer-completing-file-name
         (string= (minibuffer-contents-no-properties) "~/"))
    (delete-minibuffer-contents)
    (insert "/home/"))

   ;; When minibuffer has some file and folder names
   ((and minibuffer-completing-file-name
         (not (string= (minibuffer-contents-no-properties) "/"))
         (= (preceding-char) ?/))
    ;; Delete backward to the previous slash (without killing)
    (delete-char (- arg))
    (while (and (> (point) (minibuffer-prompt-end))
                (not (= (preceding-char) ?/)))
      (backward-delete-char 1)))

   ;; All other cases
   (t
    (delete-char (- arg)))))

(defmodule (:enabled :in-buffer)
	   (when (plist-get cfg :enabled)
	     (message "Setting up completion system")
	     (setq completion-cycle-threshold 3)
	     (setq tab-always-indent 'complete)
	     (setq completion-ignore-case t)
	     (setq read-buffer-completion-ignore-case t)
	     (setq read-file-name-completion-ignore-case t)
	     (use-package orderless
	       :init
	       (setq completion-styles '(orderless basic)
		     completion-category-defaults nil
		     completion-category-overrides
		     '((file (styles partial-completion)))))
	     (use-package vertico
	       :bind (:map minibuffer-local-map
			   ("M-h" . backward-kill-word)
			   ("" . keo/minibuffer-backward-kill))
	       :custom
	       (vertico-cycle t)
	       :init
	       (vertico-mode))
	     (use-package marginalia
	       :init
	       (marginalia-mode))
	     (use-package consult
	       :bind (("C-s" . consult-line)
		      ("C-x b" . consult-buffer)
		      ("C-x C-r" . consult-recent-file)
		      ("M-y" . consult-yank-pop)
		      ("C-c k" . consult-ripgrep)
		      ("C-c i" . consult-imenu)))
	     (use-package embark
	       :bind (("C-." . embark-act)
		      ("C-;" . embark-dwim))
	       :init
	       (setq prefix-help-command #'embark-prefix-help-command))
	     (use-package embark-consult
	       :after (embark consult))
	     (setq completion-category-overrides
		   '((eglot (styles orderless))))
	     (when (plist-get cfg :in-buffer)
	       (use-package corfu
		 :init
		 (global-corfu-mode)
		 :custom
		 (corfu-cycle t)
		 (corfu-auto t)
		 (corfu-auto-delay 0.2)
		 (corfu-auto-prefix 2)
		 (corfu-quit-at-boundary nil)
		 (corfu-quit-no-match 'separator)
		 (corfu-preview-current nil))
	       (use-package cape
		 :init
		 ;; Add useful completion-at-point functions
		 (add-to-list 'completion-at-point-functions #'cape-file)
		 (add-to-list 'completion-at-point-functions #'cape-dabbrev)
		 (add-to-list 'completion-at-point-functions #'cape-keyword))
	       (setq dabbrev-case-fold-search nil)
	       (setq dabbrev-upcase-means-case-search t)
	       )
	     ;; Configure Tempel
	     (use-package tempel
	       :bind (("M-+" . tempel-complete) ;; Alternative tempel-expand
		      ("M-*" . tempel-insert))
               
	       :init
               (setq tempel-path "~/.emacs.d/templates")
	       
	       ;; Setup completion at point
	       (defun tempel-setup-capf ()
		 ;; Add the Tempel Capf to `completion-at-point-functions'.  `tempel-expand'
		 ;; only triggers on exact matches. We add `tempel-expand' *before* the main
		 ;; programming mode Capf, such that it will be tried first.
		 (setq-local completion-at-point-functions
			     (cons #'tempel-expand completion-at-point-functions))

		 ;; Alternatively use `tempel-complete' if you want to see all matches.  Use
		 ;; a trigger prefix character in order to prevent Tempel from triggering
		 ;; unexpectly.
		 ;; (setq-local corfu-auto-trigger "/"
		 ;;             completion-at-point-functions
		 ;;             (cons (cape-capf-trigger #'tempel-complete ?/)
		 ;;                   completion-at-point-functions))
		 )

	       (add-hook 'conf-mode-hook 'tempel-setup-capf)
	       (add-hook 'prog-mode-hook 'tempel-setup-capf)
	       (add-hook 'text-mode-hook 'tempel-setup-capf)

	       ;; Optionally make the Tempel templates available to Abbrev,
	       ;; either locally or globally. `expand-abbrev' is bound to C-x '.
	       (add-hook 'prog-mode-hook #'tempel-abbrev-mode)
	       (global-tempel-abbrev-mode))


	       ;; Optional: Add tempel-collection if you want ready-made templates.
	     (use-package tempel-collection)
	     (use-package eglot-tempel
  :init
  (eglot-tempel-mode t))
))

