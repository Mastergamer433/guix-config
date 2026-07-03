;;; init.el -*- lexical-binding: t; -*-
(require 'parse-time)

(setq keo/relationship-reverse
      '(("mother" . "child")
        ("father" . "child")
        ("parent" . "child")
        ("child"  . "parent")
	("sibling" . "sibling")
        ("friend" . "friend")
        ("colleague" . "colleague")
        ("partner" . "partner")
	("aunt" . "nibling")))

;;; =========================
;;; CORE STORAGE LAYER
;;; =========================

(defun keo/org-roam--get-rel (file key)
  "Get REL_* property as list of IDs."
    (with-current-buffer (find-file-noselect file)
      (split-string (or (org-entry-get (point-min) key) "") " " t)))

(defun keo/org-roam--set-rel (file key values)
  "Set REL_* property safely."
    (with-current-buffer (find-file-noselect file)
      (goto-char (point-min))
      (if values
          (org-entry-put nil key (string-join values " "))
        (org-entry-delete nil key))
      (save-buffer)))

;;; =========================
;;; NODE HELPERS
;;; =========================

(defun keo/org-roam-read-person (&optional prompt)
  "Select a valid org-roam person node."
  (let ((node (org-roam-node-read
               nil
               (lambda (n)
                 (member "person" (org-roam-node-tags n)))
               nil
               prompt)))
    (unless (org-roam-node-p node)
      (user-error "Invalid node selected"))
    node))

(defun keo/org-roam-id-to-title (id)
  (when-let ((node (org-roam-node-from-id id)))
    (org-roam-node-title node)))

(defun keo/org-roam--field (node heading key)
  "Get KEY from HEADING section in NODE (org list format)."
  (with-current-buffer (find-file-noselect (org-roam-node-file node))
    (org-with-wide-buffer
     (goto-char (org-find-exact-headline-in-buffer heading))
     (org-end-of-meta-data)
     (let* ((items (cdr (org-list-to-lisp)))
            (match (seq-find
                    (lambda (x)
                      (string-prefix-p (concat key ":") (car x)))
                    items)))
       (when match
         (string-trim
          (substring (car match)
                     (1+ (length key)))))))))

;;; =========================
;;; RELATION LOOKUP
;;; =========================
(defun keo/org-roam--find-relation (source-id target-id)
  "Return (TYPE DIRECTION) if relation exists between SOURCE-ID and TARGET-ID."
  (let ((source (org-roam-node-from-id source-id))
        (target (org-roam-node-from-id target-id))
        found)

    ;; check SOURCE → TARGET
    (when source
      (with-current-buffer (find-file-noselect (org-roam-node-file source))
        (org-with-wide-buffer
         (goto-char (point-min))
         (dolist (type (mapcar #'car keo/relationship-reverse))
           (let ((val (org-entry-get (point-min) (concat "REL_" type))))
             (when (and val (member target-id (split-string val " " t)))
               (setq found (list type 'forward))))))))

    ;; check TARGET → SOURCE (reverse direction)
    (when (and (not found) target)
      (with-current-buffer (find-file-noselect (org-roam-node-file target))
        (org-with-wide-buffer
         (goto-char (point-min))
         (dolist (type (mapcar #'car keo/relationship-reverse))
           (let ((val (org-entry-get (point-min) (concat "REL_" type))))
             (when (and val (member source-id (split-string val " " t)))
               (setq found (list type 'reverse))))))))

    found))

;;; =========================
;;; SET RELATION
;;; =========================

(defun keo/org-roam-set-relation (&optional source target type)
  "Create bidirectional relationship between SOURCE and TARGET.
If arguments are nil, prompt interactively."
  (interactive)

  (let* ((source (or source (keo/org-roam-read-person "Source: ")))
         (target (or target (keo/org-roam-read-person "Target: ")))
         (type (or type
                   (completing-read
                    "Relationship: "
                    (mapcar #'car keo/relationship-reverse))))
         (rev (cdr (assoc type keo/relationship-reverse)))
         (sid (org-roam-node-id source))
         (tid (org-roam-node-id target))
         (sfile (org-roam-node-file source))
         (tfile (org-roam-node-file target)))

    ;; source → target
    (keo/org-roam--set-rel
     sfile
     (concat "REL_" type)
     (cons tid (keo/org-roam--get-rel sfile (concat "REL_" rev))))

    ;; target → source
    (keo/org-roam--set-rel
     tfile
     (concat "REL_" rev)
     (cons sid (keo/org-roam--get-rel tfile (concat "REL_" type))))

    (message "Linked %s ↔ %s (%s)"
             (org-roam-node-title source)
             (org-roam-node-title target)
             type)))

;;; =========================
;;; REMOVE RELATION
;;; =========================

(defun keo/org-roam-remove-relation (&optional source target)
  "Remove relationship between two people."
  (interactive)
  (let* ((source (or source (keo/org-roam-read-person "Source: ")))
         (target (or target (keo/org-roam-read-person "Target: ")))
         (sid (org-roam-node-id source))
         (tid (org-roam-node-id target))
         (old-type (keo/org-roam--find-relation sid tid)))

    (unless old-type
      (user-error "No relationship found"))

    (let* ((rev (cdr (assoc old-type keo/relationship-reverse)))
           (sfile (org-roam-node-file source))
           (tfile (org-roam-node-file target)))

      ;; remove forward
      (keo/org-roam--set-rel
       sfile
       (concat "REL_" old-type)
       (remove tid (keo/org-roam--get-rel sfile (concat "REL_" old-type))))

      ;; remove reverse
      (keo/org-roam--set-rel
       tfile
       (concat "REL_" rev)
       (remove sid (keo/org-roam--get-rel tfile (concat "REL_" rev))))

      (message "Removed %s ↔ %s (%s)"
               (org-roam-node-title source)
               (org-roam-node-title target)
               old-type))))

;;; =========================
;;; CHANGE RELATION
;;; =========================

(defun keo/org-roam-change-relation ()
  "Change an existing relationship."
  (interactive)
  (let* ((a (keo/org-roam-read-person "Person A: "))
         (b (keo/org-roam-read-person "Person B: "))
         (a-id (org-roam-node-id a))
         (b-id (org-roam-node-id b))
         (old (keo/org-roam--find-relation a-id b-id)))

    (unless old
      (user-error "No existing relationship"))

    (let ((new (completing-read
                (format "Change %s → " old)
                (mapcar #'car keo/relationship-reverse))))

      (keo/org-roam-remove-relation a b)
      (keo/org-roam-set-relation a b new)

      (message "Changed %s ↔ %s : %s → %s"
               (org-roam-node-title a)
               (org-roam-node-title b)
               old
               new))))

(defun keo/org-add-repeater-to-string (timestamp repeater)
  "Add REPEATER (e.g. \"+1y\") to Org TIMESTAMP string."
  (if (string-match "\\(.*?\\)>\\'" timestamp)
      (concat (match-string 1 timestamp) " " repeater ">")
    timestamp))

(defun roamcrm-parse-birthday (s)
  (encode-time (parse-time-string s)))

;; (defun roamcrm-sync-birthdays ()
;;   (interactive)
;;   (with-temp-file "~/org/birthdays.org"
;;     (insert "#+TITLE: Birthdays\n\n")

;;     (dolist (node (org-roam-node-list))
;;       (let ((bday (keo/org-roam--field node "Info" "Birthday"))
;;             (name (org-roam-node-title node)))
;;         (when bday
;;           (insert (format "* %s\n%s\n\n" name (keo/org-add-repeater-to-string bday "+1y"))))))))

;(roamcrm-sync-birthdays)

(defun keo/org-font-setup ()
  ;; Pretty bullets
  (font-lock-add-keywords
   'org-mode
   '(("^ *\\nn([-]\\) "
      (0 (prog1 ()
           (compose-region (match-beginning 1)
                           (match-end 1) "•"))))))

  ;; Only apply fonts in GUI
  (when (display-graphic-p)
    (dolist (face '((org-level-1 . 1.3)
                    (org-level-2 . 1.2)
                    (org-level-3 . 1.1)
                    (org-level-4 . 1.05)))
      (set-face-attribute (car face) nil
                          :font "Fira Code"
                          :weight 'medium
                          :height (cdr face))))

  ;; Fixed pitch areas
  (dolist (face '(org-block org-code org-table org-verbatim org-checkbox))
    (set-face-attribute face nil :inherit 'fixed-pitch)))

(defun keo/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (visual-line-mode 1))

(defun keo/org-mode-visual-fill ()
  (setq visual-fill-column-width 100
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(defmodule (:enabled :org-dir :org-roam-dir)
	   (when (plist-get cfg :enabled)
	     (use-package org
  :hook (org-mode . keo/org-mode-setup)
  :config
  (setq org-directory (plist-get cfg :org-dir)
        org-ellipsis " ▾"

        ;; Agenda
        org-agenda-files `("~/org/birthdays.org")

        ;; Logging
        org-log-done 'time
        org-log-into-drawer t

        ;; Refile
        org-refile-targets '((org-agenda-files :maxlevel . 3))
        org-outline-path-complete-in-steps nil
        org-refile-use-outline-path t))
	     
	     (use-package org-ql)
	     
(use-package org-bullets
  :hook (org-mode . org-bullets-mode))

(use-package visual-fill-column
  :hook (org-mode . keo/org-mode-visual-fill))
(let ((roam-dir (plist-get cfg :org-roam-dir)))
(use-package org-roam
  :init
  (setq org-roam-v2-ack t)

  :config
  (setq org-roam-directory roam-dir)
  (add-to-list 'org-roam-capture-templates
             '("p" "person" plain "%?"
               :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                                  "#+title: ${title}\n#+filetags: :person:\n\n* Info\n- Email:\n- Phone:\n- Company:\n- Location:\n\n* Interactions\n\n* Notes\n")
               :unnarrowed t))
  (org-roam-db-autosync-mode))
(global-set-key (kbd "C-c n r") #'keo/org-roam-set-relation))
))
