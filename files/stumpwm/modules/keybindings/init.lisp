(in-package :stumpwm)

(defmodule (:enabled)
  (when (getf cfg :enabled)
    (message "Keybindings module enabled")
    ;; Example keybinding
    (define-key *root-map* (kbd "C-c t") (lambda () (message "Test key pressed")))))
