(in-package :stumpwm)

(setf *config-options*
      '((ui
         :enabled t
         :font "Fira Code")

        (completion
         :enabled t
         :in-buffer t)

        (programming
         :enabled t
         (rust
          :enabled t)
         (lisp
          :enabled t))))

(load-modules-recursive nil *config-options*)
