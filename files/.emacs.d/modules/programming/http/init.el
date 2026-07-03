(defmodule (:enabled)
	   (when (plist-get cfg :enabled)
             (use-package verb
	       :config
	       (org-babel-do-load-languages
		'org-babel-load-languages
		'((verb . t))))))
