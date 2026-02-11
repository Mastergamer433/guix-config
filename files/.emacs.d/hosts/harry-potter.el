(setq my/config-options
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

(my/load-modules-recursive nil my/config-options)

(use-package request)

(defun simpsons-quote-buffer ()
  "Open a buffer showing a random Simpsons character image and quote."
  (interactive)
  (let* ((characters '(1 2 3 4 5 6 7 8 9 13 14 15 16 17 18 37))
         (cid (seq-random-elt characters))
         (api-url (format "https://thesimpsonsapi.com/api/characters/%d" cid))
         (buf (get-buffer-create "*Simpsons Quote*")))
    ;; fetch JSON
    (with-current-buffer (url-retrieve-synchronously api-url t t)
      (goto-char (point-min))
      (re-search-forward "\n\n")
      (let* ((json-data (json-read))
             (name (alist-get 'name json-data))
             (phrases (alist-get 'phrases json-data))
             (quote (when (and (vectorp phrases) (> (length phrases) 0))
                      (aref phrases (random (length phrases)))))
             (ppath (alist-get 'portrait_path json-data))
             (full-img-url (when ppath (concat "https://thesimpsonsapi.com" ppath)))
             (tmp-webp (when full-img-url (make-temp-file "simpson" nil ".webp")))
             (tmp-png (when full-img-url (make-temp-file "simpson" nil ".png"))))
        (with-current-buffer buf
          (read-only-mode -1)
          (erase-buffer)
          ;; download image to temp file
          (when full-img-url
            (url-copy-file full-img-url tmp-webp t)
            (when (and (executable-find "convert")
                       (file-exists-p tmp-webp))
              (call-process "convert" nil nil nil tmp-webp tmp-png)
              (when (file-exists-p tmp-png)
                (insert-image (create-image tmp-png))
                (insert "\n\n"))))
          ;; insert name and quote
          (when name (insert (format "%s\n\n" name)))
          (when quote (insert (format "💬 %s\n\n" quote)))
          (goto-char (point-min))
          (read-only-mode 1))))
    (pop-to-buffer buf)))
