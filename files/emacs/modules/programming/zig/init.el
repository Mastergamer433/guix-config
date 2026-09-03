(setq module-schema '(:enabled))

(defmodule (:enabled)
	   (when (plist-get cfg :enabled)
	     (use-package zig-mode
	       :mode "\\.zig\\'"
	       :hook ((zig-mode . eglot-ensure)))))
