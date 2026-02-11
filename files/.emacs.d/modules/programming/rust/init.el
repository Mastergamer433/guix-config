(setq module-schema '(:enabled))

(defmodule (:enabled)
	   (when (plist-get cfg :enabled)
	     (use-package rust-mode
	       :mode "\\.rs\\'"
	       :hook ((rust-mode . eglot-ensure)))
	     (use-package cargo
	       :ensure t
	       :hook (rust-mode . cargo-minor-mode))))
