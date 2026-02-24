
(setq module-schema '(:enabled :font))

(defmodule (:vterm :eat)
	   (when (plist-get cfg :vterm)
	     (message "Setting up vterm")
             (use-package vterm)
             )
	   (when (plist-get cfg :eat)
	     (message "Setting up eat")
	     (use-package eat)))
