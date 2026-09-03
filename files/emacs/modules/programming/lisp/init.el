(setq module-schema '(:enabled))

(defmodule (:enabled)
	   (when (plist-get cfg :enabled)
	     (use-package paredit
	       :config
	       ;; Optional keybindings for Paredit navigation
	       (define-key paredit-mode-map (kbd "M-)") 'paredit-forward-slurp-sexp)
	       (define-key paredit-mode-map (kbd "M-(") 'paredit-forward-barf-sexp)
	       (define-key paredit-mode-map (kbd "M-}") 'paredit-backward-slurp-sexp)
	       (define-key paredit-mode-map (kbd "M-{") 'paredit-backward-barf-sexp))))

