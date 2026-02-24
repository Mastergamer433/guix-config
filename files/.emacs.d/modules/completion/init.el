(setq module-schema '(:enabled :in-buffer))
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
    (delete-char (- arg))
    (zap-up-to-char (- arg) ?/))

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
	     ))

