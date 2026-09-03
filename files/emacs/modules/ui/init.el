(defmodule (:enabled :font)
	   (when (plist-get cfg :enabled)
	     (message "Setting up basic UI customizations")
	     (setq inhibit-startup-message t)
	     (scroll-bar-mode -1)
	     (tool-bar-mode -1)
	     (tooltip-mode -1)
	     (set-fringe-mode 10)
	     (menu-bar-mode -0)
	     (setq visible-bell t)
	     (setq mouse-wheel-scroll-amount '(1 ((shift) .1))
		   mouse-wheel-progressive-speed nil
		   mouse-wheel-follow-mouse 't
		   scroll-step 1
		   use-dialog-box nil)
	     (column-number-mode)
	     (global-display-line-numbers-mode t)
	     (global-hl-line-mode t)
	     (setq large-file-warning-threshold nil)
	     (setq vc-follow-symlinks t)
	     (setq ad-redifintion-action 'accept)
	     (let ((font (plist-get cfg :font)))
	       (set-face-attribute 'default nil :font font :height 110)
	       (set-face-attribute 'fixed-pitch nil :font font)
	       (set-face-attribute 'variable-pitch nil :font font :height 120 :weight 'regular))
	     (setq display-time-format "%l:%M %p %b %d"
		   display-time-load-average-threshold 0.0)
	     (use-package all-the-icons)
	     (use-package nerd-icons)
	     (use-package emojify)
	     (use-package timu-spacegrey-theme
	       :config
	       (load-theme 'timu-spacegrey t))))

