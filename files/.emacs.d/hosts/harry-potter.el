(setq my/config-options
      '((ui
	 :enabled t
	 :window-management t
	 :font "Fira Code")
	(completion
	 :enabled t
	 :in-buffer t)
        (terms
	 :eat t)
        (programming
	 :enabled t
	 (rust
	  :enabled t)
	 (lisp
	  :enabled t))))

(my/load-modules-recursive nil my/config-options)
