;;; init.el -*- lexical-binding: t; -*-

(require 'parse-time)
(require 'seq)


;;; ============================================================
;;; RELATIONSHIPS
;;; ============================================================

(defconst keo/relationship-reverse
  '(("mother"    . "child")
    ("father"    . "child")
    ("parent"    . "child")
    ("child"     . "parent")
    ("sibling"   . "sibling")
    ("friend"    . "friend")
    ("colleague" . "colleague")
    ("partner"   . "partner")
    ("aunt"      . "nibling"))
  "Mapping of relationship types to reciprocal relationship types.")


;;; ============================================================
;;; GENERIC HELPERS
;;; ============================================================

(defun keo/uniq (values)
  "Remove duplicate VALUES while preserving order."
  (let (result)
    (dolist (value values (nreverse result))
      (unless (member value result)
        (push value result)))))


(defun keo/add-value (value values)
  "Add VALUE to VALUES if it isn't already present."
  (if (member value values)
      values
    (cons value values)))


(defun keo/remove-value (value values)
  "Remove VALUE from VALUES."
  (delete value (copy-sequence values)))


(defun keo/with-file (file function)
  "Call FUNCTION with FILE's buffer current."
  (with-current-buffer
      (find-file-noselect file)
    (funcall function)))


(defun keo/save-current-buffer ()
  "Save current buffer when modified."
  (when (buffer-modified-p)
    (save-buffer)))


;;; ============================================================
;;; FILE / NODE HELPERS
;;; ============================================================

(defun keo/org-roam-files ()
  "Return all files known to Org-roam."
  (org-roam-list-files))


(defun keo/org-roam-file-title (file)
  "Return #+title from FILE."
  (keo/with-file
   file
   (lambda ()
     (save-restriction
       (widen)
       (goto-char (point-min))
       (or
        (org-entry-get nil "TITLE")
        (when (re-search-forward
               "^#\\+title:[ \t]*\\(.+\\)$"
               nil
               t)
          (string-trim
           (match-string-no-properties 1)))
        (file-name-base file))))))


(defun keo/org-roam-file-tags (file)
  "Return #+filetags from FILE as a list."
  (keo/with-file
   file
   (lambda ()
     (save-restriction
       (widen)
       (goto-char (point-min))

       (when
           (re-search-forward
            "^#\\+filetags:[ \t]*\\(.+\\)$"
            nil
            t)

         (let ((tags
                (string-trim
                 (match-string-no-properties 1))))

           (split-string
            (replace-regexp-in-string
             ":[ \t]*"
             " "
             tags)
            "[ \t]+"
            t)))))))


(defun keo/org-roam-person-file-p (file)
  "Return non-nil when FILE is tagged as a person."
  (member
   "person"
   (keo/org-roam-file-tags file)))


(defun keo/org-roam-person-files ()
  "Return all Org-roam files tagged as people."
  (seq-filter
   #'keo/org-roam-person-file-p
   (keo/org-roam-files)))


;;; ============================================================
;;; PERSON SELECTION
;;; ============================================================

(defun keo/org-roam-person-candidates ()
  "Return person completion candidates."
  (mapcar
   (lambda (file)
     (cons
      (keo/org-roam-file-title file)
      file))
   (keo/org-roam-person-files)))


(defun keo/org-roam-read-person (&optional prompt)
  "Select a person Org-roam file."
  (let* ((candidates
          (keo/org-roam-person-candidates))
         (choice
          (completing-read
           (or prompt "Person: ")
           candidates
           nil
           t))
         (file
          (cdr
           (assoc choice candidates))))

    (unless file
      (user-error "Invalid person selected"))

    file))


;;; ============================================================
;;; ORG PROPERTIES
;;; ============================================================

(defun keo/org-get-property-values (file key)
  "Return KEY property from FILE as a list."
  (keo/with-file
   file
   (lambda ()
     (goto-char (point-min))
     (split-string
      (or (org-entry-get nil key) "")
      "[ \t]+"
      t))))


(defun keo/org-set-property-values
    (file key values)
  "Set KEY in FILE to VALUES."
  (keo/with-file
   file
   (lambda ()
     (goto-char (point-min))

     (if values
         (org-entry-put
          nil
          key
          (string-join
           (keo/uniq values)
           " "))
       (org-entry-delete
        nil
        key))

     (keo/save-current-buffer))))


(defun keo/org-add-property-value
    (file key value)
  "Add VALUE to KEY in FILE."
  (keo/org-set-property-values
   file
   key
   (keo/add-value
    value
    (keo/org-get-property-values
     file
     key))))


(defun keo/org-remove-property-value
    (file key value)
  "Remove VALUE from KEY in FILE."
  (keo/org-set-property-values
   file
   key
   (keo/remove-value
    value
    (keo/org-get-property-values
     file
     key))))


;;; ============================================================
;;; PERSON IDENTIFIERS
;;; ============================================================

(defun keo/org-roam-file-id (file)
  "Return the ID stored in FILE."
  (keo/with-file
   file
   (lambda ()
     (goto-char (point-min))
     (or
      (org-entry-get nil "ID")
      (when
          (re-search-forward
           "^:ID:[ \t]*\\(.+\\)$"
           nil
           t)
        (string-trim
         (match-string-no-properties 1)))))))


(defun keo/org-roam-file-by-id (id)
  "Find the Org-roam file containing ID."
  (seq-find
   (lambda (file)
     (equal
      id
      (keo/org-roam-file-id file)))
   (keo/org-roam-files)))


(defun keo/org-roam-file-by-title (title)
  "Find person file whose title is TITLE."
  (seq-find
   (lambda (file)
     (equal
      title
      (keo/org-roam-file-title file)))
   (keo/org-roam-person-files)))


;;; ============================================================
;;; RELATIONSHIP HELPERS
;;; ============================================================

(defun keo/relationship-types ()
  "Return all relationship types."
  (mapcar
   #'car
   keo/relationship-reverse))


(defun keo/relationship-reverse-type (type)
  "Return reciprocal relationship type for TYPE."
  (or
   (cdr
    (assoc
     type
     keo/relationship-reverse))

   (user-error
    "Unknown relationship type: %s"
    type)))


(defun keo/relationship-key (type)
  "Return Org property key for TYPE."
  (concat "REL_" type))


(defun keo/relationship-read-type ()
  "Read a relationship type."
  (completing-read
   "Relationship: "
   (keo/relationship-types)
   nil
   t))


(defun keo/relationship-target-ids
    (file type)
  "Return IDs related through TYPE in FILE."
  (keo/org-get-property-values
   file
   (keo/relationship-key type)))


(defun keo/relationship-target-p
    (file type target-id)
  "Return non-nil when FILE relates to TARGET-ID via TYPE."
  (member
   target-id
   (keo/relationship-target-ids
    file
    type)))


(defun keo/relationship-find-type
    (file target-id)
  "Find relationship TYPE from FILE to TARGET-ID."
  (seq-some
   (lambda (type)
     (when
         (keo/relationship-target-p
          file
          type
          target-id)
       type))
   (keo/relationship-types)))


;;; ============================================================
;;; RELATIONSHIP LOOKUP
;;; ============================================================

(defun keo/org-roam--find-relation
    (source-id target-id)
  "Find relationship between SOURCE-ID and TARGET-ID.

Return `(TYPE DIRECTION)' or nil."
  (let ((source-file
         (keo/org-roam-file-by-id source-id))
        (target-file
         (keo/org-roam-file-by-id target-id)))

    (or

     ;; SOURCE -> TARGET
     (when source-file
       (when-let
           ((type
             (keo/relationship-find-type
              source-file
              target-id)))
         (list type 'forward)))

     ;; TARGET -> SOURCE
     (when target-file
       (when-let
           ((type
             (keo/relationship-find-type
              target-file
              source-id)))
         (list type 'reverse))))))


;;; ============================================================
;;; RELATIONSHIP STORAGE
;;; ============================================================

(defun keo/relationship-add-one
    (file type target-id)
  "Add TARGET-ID to TYPE relationship in FILE."
  (keo/org-add-property-value
   file
   (keo/relationship-key type)
   target-id))


(defun keo/relationship-remove-one
    (file type target-id)
  "Remove TARGET-ID from TYPE relationship in FILE."
  (keo/org-remove-property-value
   file
   (keo/relationship-key type)
   target-id))


(defun keo/relationship-add-both
    (source-file target-file source-id target-id type)
  "Create TYPE relationship in both directions."
  (let ((reverse
         (keo/relationship-reverse-type type)))

    (keo/relationship-add-one
     source-file
     type
     target-id)

    (keo/relationship-add-one
     target-file
     reverse
     source-id)))


(defun keo/relationship-remove-both
    (source-file target-file source-id target-id type)
  "Remove TYPE relationship in both directions."
  (let ((reverse
         (keo/relationship-reverse-type type)))

    (keo/relationship-remove-one
     source-file
     type
     target-id)

    (keo/relationship-remove-one
     target-file
     reverse
     source-id)))


;;; ============================================================
;;; RELATIONSHIP OPERATIONS
;;; ============================================================

(defun keo/relationship-add
    (source-file target-file type)
  "Create TYPE relationship between two person files."
  (let ((source-id
         (keo/org-roam-file-id source-file))
        (target-id
         (keo/org-roam-file-id target-file)))

    (unless source-id
      (user-error
       "No ID found in %s"
       source-file))

    (unless target-id
      (user-error
       "No ID found in %s"
       target-file))

    (keo/relationship-add-both
     source-file
     target-file
     source-id
     target-id
     type)))


(defun keo/relationship-remove
    (source-file target-file type)
  "Remove TYPE relationship between two person files."
  (let ((source-id
         (keo/org-roam-file-id source-file))
        (target-id
         (keo/org-roam-file-id target-file)))

    (keo/relationship-remove-both
     source-file
     target-file
     source-id
     target-id
     type)))


;;; ============================================================
;;; INTERACTIVE COMMANDS
;;; ============================================================

(defun keo/org-roam-set-relation
    (&optional source target type)
  "Create bidirectional relationship."
  (interactive)

  (let* ((source
          (or source
              (keo/org-roam-read-person
               "Source: ")))

         (target
          (or target
              (keo/org-roam-read-person
               "Target: ")))

         (type
          (or type
              (keo/relationship-read-type))))

    (keo/relationship-add
     source
     target
     type)

    (message
     "Linked %s ↔ %s (%s)"
     (keo/org-roam-file-title source)
     (keo/org-roam-file-title target)
     type)))


(defun keo/org-roam-remove-relation
    (&optional source target)
  "Remove relationship between two people."
  (interactive)

  (let* ((source
          (or source
              (keo/org-roam-read-person
               "Source: ")))

         (target
          (or target
              (keo/org-roam-read-person
               "Target: ")))

         (source-id
          (keo/org-roam-file-id source))

         (target-id
          (keo/org-roam-file-id target))

         (relation
          (keo/org-roam--find-relation
           source-id
           target-id)))

    (unless relation
      (user-error
       "No relationship found"))

    (let ((type
           (car relation)))

      (keo/relationship-remove
       source
       target
       type)

      (message
       "Removed %s ↔ %s (%s)"
       (keo/org-roam-file-title source)
       (keo/org-roam-file-title target)
       type))))


(defun keo/org-roam-change-relation ()
  "Change an existing relationship."
  (interactive)

  (let* ((source
          (keo/org-roam-read-person
           "Person A: "))

         (target
          (keo/org-roam-read-person
           "Person B: "))

         (source-id
          (keo/org-roam-file-id source))

         (target-id
          (keo/org-roam-file-id target))

         (relation
          (keo/org-roam--find-relation
           source-id
           target-id)))

    (unless relation
      (user-error
       "No existing relationship"))

    (let* ((old-type
            (car relation))

           (new-type
            (completing-read
             (format
              "Change %s → "
              old-type)
             (keo/relationship-types)
             nil
             t)))

      (keo/relationship-remove
       source
       target
       old-type)

      (keo/relationship-add
       source
       target
       new-type)

      (message
       "Changed %s ↔ %s : %s → %s"
       (keo/org-roam-file-title source)
       (keo/org-roam-file-title target)
       old-type
       new-type))))


;;; ============================================================
;;; BIRTHDAYS
;;; ============================================================

(defun keo/org-add-repeater-to-string
    (timestamp repeater)
  "Add REPEATER to Org TIMESTAMP."
  (if (string-match
       "\\(.*?\\)>\\'"
       timestamp)

      (concat
       (match-string 1 timestamp)
       " "
       repeater
       ">")

    timestamp))


(defun roamcrm-parse-birthday (string)
  "Parse birthday STRING."
  (encode-time
   (parse-time-string string)))


;;; ============================================================
;;; ORG VISUALS
;;; ============================================================

(defun keo/org-enable-pretty-bullets ()
  "Replace Org list bullets with pretty bullets."
  (font-lock-add-keywords
   'org-mode
   '(("^ *\\([-]\\) "
      (0
       (prog1 ()
         (compose-region
          (match-beginning 1)
          (match-end 1)
          "•")))))))


(defun keo/org-set-heading-face
    (face height)
  "Set FACE to HEIGHT."
  (set-face-attribute
   face
   nil
   :font "Fira Code"
   :weight 'medium
   :height height))


(defun keo/org-set-heading-faces ()
  "Configure Org heading faces."
  (when (display-graphic-p)

    (dolist
        (face
         '((org-level-1 . 1.3)
           (org-level-2 . 1.2)
           (org-level-3 . 1.1)
           (org-level-4 . 1.05)))

      (keo/org-set-heading-face
       (car face)
       (cdr face)))))


(defun keo/org-set-fixed-pitch-face (face)
  "Make FACE fixed pitch."
  (set-face-attribute
   face
   nil
   :inherit 'fixed-pitch))


(defun keo/org-set-fixed-pitch-faces ()
  "Configure fixed-pitch Org faces."
  (dolist
      (face
       '(org-block
         org-code
         org-table
         org-verbatim
         org-checkbox))

    (keo/org-set-fixed-pitch-face
     face)))


(defun keo/org-font-setup ()
  "Configure Org fonts."
  (keo/org-enable-pretty-bullets)
  (keo/org-set-heading-faces)
  (keo/org-set-fixed-pitch-faces))


;;; ============================================================
;;; ORG MODE
;;; ============================================================

(defun keo/org-mode-setup ()
  "Configure Org mode."
  (org-indent-mode)
  (variable-pitch-mode 1)
  (visual-line-mode 1))


(defun keo/org-mode-visual-fill ()
  "Configure visual fill column."
  (setq-local
   visual-fill-column-width
   100)

  (setq-local
   visual-fill-column-center-text
   t)

  (visual-fill-column-mode 1))


;;; ============================================================
;;; ORG MODULE
;;; ============================================================

(defmodule
    (:enabled :org-dir :org-roam-dir)

  (when (plist-get cfg :enabled)

    ;; ----------------------------------------------------------
    ;; Org
    ;; ----------------------------------------------------------

    (use-package org
      :hook ((org-mode . keo/org-mode-setup)
             (org-mode . keo/org-font-setup))

      :config

      (setq
       org-directory
       (plist-get cfg :org-dir)

       org-ellipsis
       " ▾"

       org-agenda-files
       '("~/org/birthdays.org")

       org-log-done
       'time

       org-log-into-drawer
       t

       org-refile-targets
       '((org-agenda-files :maxlevel . 3))

       org-outline-path-complete-in-steps
       nil

       org-refile-use-outline-path
       t))


    ;; ----------------------------------------------------------
    ;; Org QL
    ;; ----------------------------------------------------------

    (use-package org-ql)


    ;; ----------------------------------------------------------
    ;; Org Bullets
    ;; ----------------------------------------------------------

    (use-package org-bullets
      :hook
      (org-mode . org-bullets-mode))


    ;; ----------------------------------------------------------
    ;; Visual Fill Column
    ;; ----------------------------------------------------------

    (use-package visual-fill-column
      :hook
      (org-mode . keo/org-mode-visual-fill))


    ;; ----------------------------------------------------------
    ;; Org Roam
    ;; ----------------------------------------------------------

    (let ((roam-dir
           (plist-get cfg :org-roam-dir)))

      (use-package org-roam

        :init

        (setq
         org-roam-v2-ack
         t)

        :config

        (setq
         org-roam-directory
         roam-dir)

        (add-to-list
         'org-roam-capture-templates

         '("p"
           "person"
           plain
           "%?"

           :target
           (file+head
            "%<%Y%m%d%H%M%S>-${slug}.org"

            "#+title: ${title}\n\
#+filetags: :person:\n\n\
* Info\n\
- Email:\n\
- Phone:\n\
- Company:\n\
- Location:\n\n\
* Interactions\n\n\
* Notes\n")

           :unnarrowed
           t))

        (org-roam-db-autosync-mode)

        (global-set-key
         (kbd "C-c n r")
         #'keo/org-roam-set-relation)))))
