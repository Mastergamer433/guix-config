(defmodule (:enabled)
	   (when (plist-get cfg :enabled)
	     (use-package haskell-mode
	       :straight (haskell-mode :type git :host github :repo "haskell/haskell-mode")
	       :mode "\\.hs\\'")))
