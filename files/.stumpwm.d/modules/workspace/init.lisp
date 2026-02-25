(in-package :stumpwm)

(defmodule (:enabled :num)
  (let ((enabled (getf cfg :enabled))
        (num (getf cfg :num 1)))
    (when enabled
      (message "Workspace module enabled: creating ~A workspaces" num)
      ;; Example: create workspaces
      (dotimes (i num)
	(gnewbg i)
        (message "Created workspace ~A" (1+ i))))))
