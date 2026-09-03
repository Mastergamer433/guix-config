(defmodule (:enabled)
	   (when (plist-get cfg :enabled)
	     (use-package go-mode
	       :mode "\\.go\\'"
	       :hook ((go-mode . eglot-ensure)))))
