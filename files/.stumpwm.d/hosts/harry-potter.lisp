(in-package :stumpwm)

(setf *config-options*
      '((ui
         :enabled t)
	(workspaces
	 :enabled t
	 :num 10))

        
(load-modules-recursive nil *config-options*)
