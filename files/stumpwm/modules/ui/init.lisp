(in-package :stumpwm)

(defmodule (:enabled :theme :font)
  (let ((enabled (getf cfg :enabled))
        (theme (getf cfg :theme))
        (font (getf cfg :font)))
    (when enabled
      (message "UI module enabled: theme=~A, font=~A" theme font)
      ;; Example: set the default font
      (setf *default-font* font)
      ;; Example: pretend to set theme
      (setf *theme* theme))))
