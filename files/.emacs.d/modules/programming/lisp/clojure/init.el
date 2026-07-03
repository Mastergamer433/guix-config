(defmodule (:enabled)
	   (when (plist-get cfg :enabled)
	     (use-package clojure-mode
	       :mode "\\.clj\\'"
	       :hook ((clojure-mode . eglot-ensure)))
	     (use-package cider
	       :hook ((clojure-mode . cider-mode)))))


