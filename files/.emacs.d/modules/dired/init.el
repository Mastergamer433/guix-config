(defmodule (:enabled :font)
	   (when (plist-get cfg :enabled)
	     (use-package dired
	       :straight nil
	       :hook (dired-mode . auto-revert-mode)
	       :config
	       (setq dired-listing-switches "-alh --group-directories-first"
		     dired-dwim-target t
		     dired-recursive-copies 'always
		     dired-recursive-deletes 'top))
	     (use-package dired-x
	       :straight nil)
	     (use-package dired-narrow
	       :bind (:map dired-mode-map
			   ("/" . dired-narrow)))
	     (use-package peep-dired
	       :bind (:map dired-mode-map
			   ("P" . peep-dired)))
	     (use-package diredfl
	       :hook (dired-mode . diredfl-mode))
	     (use-package async
	       :config
	       (dired-async-mode 1))))
