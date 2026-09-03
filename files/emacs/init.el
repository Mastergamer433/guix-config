(load (expand-file-name "base.el" user-emacs-directory))

(let ((host (system-name))
      (hosts-dir (expand-file-name "hosts" user-emacs-directory)))
  (let ((host-file (expand-file-name (concat host ".el") hosts-dir)))
    (if (file-exists-p host-file)
        (load host-file)
      (message "No host config found for %s" host))))
