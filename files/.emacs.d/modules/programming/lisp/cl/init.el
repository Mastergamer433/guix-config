(defmodule (:enabled)
	   (when (plist-get cfg :enabled)
	     (use-package sly)))
