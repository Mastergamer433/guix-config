;;; roamcrm-cli.el -*- lexical-binding: t; -*-


;;; ============================================================
;;; SETUP
;;; ============================================================

(setq package-user-dir
      (expand-file-name "~/roamcrm-cli-packages/"))

(require 'package)

(setq package-archives
      '(("gnu"  . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))

(setq inhibit-message t)

(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(dolist (pkg '(org org-roam))
  (unless (package-installed-p pkg)
    (package-install pkg)))

(setq org-roam-directory
      (expand-file-name "~/notes/"))

(org-roam-db-autosync-mode)


;;; ============================================================
;;; GENERIC HELPERS
;;; ============================================================

(defun roamcrm--uniq (values)
  "Return VALUES without duplicates."
  (let (result)
    (dolist (value values (nreverse result))
      (unless (member value result)
        (push value result)))))


(defun roamcrm--first (function values)
  "Return first VALUE for which FUNCTION returns non-nil."
  (seq-some function values))


(defun roamcrm--nonempty (value)
  "Return VALUE when it is non-empty."
  (when (and value
             (not (string-empty-p
                   (string-trim value))))
    (string-trim value)))


;;; ============================================================
;;; ORG-ROAM FILES
;;; ============================================================

(defun roamcrm--all-files ()
  "Return all files known to Org-roam."
  (org-roam-list-files))


(defun roamcrm--with-file (file function)
  "Call FUNCTION with FILE's buffer current."
  (with-current-buffer
      (find-file-noselect file)
    (save-excursion
      (save-restriction
        (widen)
        (funcall function)))))


(defun roamcrm--file-title (file)
  "Return the title of FILE."
  (roamcrm--with-file
   file
   #'roamcrm--current-file-title))


(defun roamcrm--current-file-title ()
  "Return the title of the current file."
  (goto-char (point-min))

  (or
   ;; Standard Org keyword.
   (when
       (re-search-forward
        "^#\\+title:[ \t]*\\(.+\\)$"
        nil
        t)
     (string-trim
      (match-string-no-properties 1)))

   ;; Fallback.
   (file-name-base
    (or buffer-file-name
        ""))))


(defun roamcrm--file-tags (file)
  "Return file tags from FILE."
  (roamcrm--with-file
   file
   #'roamcrm--current-file-tags))


(defun roamcrm--current-file-tags ()
  "Return #+filetags from the current file."
  (goto-char (point-min))

  (when
      (re-search-forward
       "^#\\+filetags:[ \t]*\\(.+\\)$"
       nil
       t)

    (let ((tags
           (string-trim
            (match-string-no-properties 1))))

      ;; Convert :person: :foo: into ("person" "foo").
      (delete-dups
       (split-string
        (replace-regexp-in-string
         ":" " "
         tags)
        "[ \t]+"
        t)))))


(defun roamcrm--person-file-p (file)
  "Return non-nil when FILE represents a person."
  (member
   "person"
   (roamcrm--file-tags file)))


(defun roamcrm--people-files ()
  "Return all person files."
  (seq-filter
   #'roamcrm--person-file-p
   (roamcrm--all-files)))


;;; ============================================================
;;; FILE IDs
;;; ============================================================

(defun roamcrm--current-file-id ()
  "Return the Org ID of the current file."
  (goto-char (point-min))

  (or

   ;; Property drawer / file property.
   (when
       (re-search-forward
        "^:ID:[ \t]*\\(.+\\)$"
        nil
        t)
     (string-trim
      (match-string-no-properties 1)))

   ;; Org keyword fallback.
   (when
       (re-search-forward
        "^#\\+id:[ \t]*\\(.+\\)$"
        nil
        t)
     (string-trim
      (match-string-no-properties 1)))

   ;; Generic ID property fallback.
   (when
       (re-search-forward
        "^[ \t]*:ID:[ \t]*\\(.+\\)$"
        nil
        t)
     (string-trim
      (match-string-no-properties 1)))))


(defun roamcrm--file-id (file)
  "Return Org ID from FILE."
  (roamcrm--with-file
   file
   #'roamcrm--current-file-id))


(defun roamcrm--find-file-by-id (id)
  "Find Org-roam file with ID."
  (roamcrm--first
   (lambda (file)
     (when
         (equal
          id
          (roamcrm--file-id file))
       file))
   (roamcrm--all-files)))


(defun roamcrm--find-file-by-title (title)
  "Find Org-roam file with TITLE."
  (roamcrm--first
   (lambda (file)
     (when
         (equal
          title
          (roamcrm--file-title file))
       file))
   (roamcrm--all-files)))


(defun roamcrm--resolve-file (input)
  "Resolve INPUT as an Org ID or title."
  (or
   (roamcrm--find-file-by-id input)
   (roamcrm--find-file-by-title input)))


(defun roamcrm--resolve-person (input)
  "Resolve INPUT as a person ID or title."
  (let ((file
         (roamcrm--resolve-file input)))
    (when
        (and file
             (roamcrm--person-file-p file))
      file)))


(defun roamcrm--title (id)
  "Return title for ID."
  (when-let
      ((file
        (roamcrm--find-file-by-id id)))
    (roamcrm--file-title file)))


;;; ============================================================
;;; PERSON LISTING
;;; ============================================================

(defun roamcrm--person-summary (file)
  "Return `(ID . TITLE)' for person FILE."
  (cons
   (roamcrm--file-id file)
   (roamcrm--file-title file)))


(defun roamcrm--person-summaries ()
  "Return summaries for all people."
  (mapcar
   #'roamcrm--person-summary
   (roamcrm--people-files)))


;;; ============================================================
;;; RELATIONSHIP PARSING
;;; ============================================================

(defun roamcrm--parse-rel-line ()
  "Parse the current REL property match."
  (cons
   (match-string-no-properties 1)
   (split-string
    (match-string-no-properties 2)
    "[ \t]+"
    t)))


(defun roamcrm--current-relationships ()
  "Return relationships from the current file."
  (goto-char (point-min))

  (let (relationships)

    (while
        (re-search-forward
         "^:REL_\\([^:]+\\):[ \t]+\\(.+\\)$"
         nil
         t)

      (push
       (roamcrm--parse-rel-line)
       relationships))

    (nreverse relationships)))


(defun roamcrm--relationships (file)
  "Return relationships from FILE."
  (roamcrm--with-file
   file
   #'roamcrm--current-relationships))


(defun roamcrm--relationship-targets
    (relationship)
  "Return target IDs from RELATIONSHIP."
  (cdr relationship))


(defun roamcrm--relationship-type
    (relationship)
  "Return type from RELATIONSHIP."
  (car relationship))


(defun roamcrm--relations-between
    (file target-id)
  "Return relationship types from FILE to TARGET-ID."
  (let (found)

    (dolist
        (relationship
         (roamcrm--relationships file))

      (when
          (member
           target-id
           (roamcrm--relationship-targets
            relationship))

        (push
         (roamcrm--relationship-type
          relationship)
         found)))

    (nreverse found)))


;;; ============================================================
;;; ORG LIST FIELD PARSER
;;; ============================================================

(defun roamcrm--field-item-p (item key)
  "Return non-nil when ITEM contains KEY."
  (and
   (consp item)
   (stringp (car item))
   (string-prefix-p
    (concat key ":")
    (car item))))


(defun roamcrm--field-item-value (item key)
  "Extract KEY's value from ITEM."
  (when
      (roamcrm--field-item-p item key)

    (string-trim
     (substring
      (car item)
      (1+ (length key))))))


(defun roamcrm--current-section-items (heading)
  "Return list items belonging to HEADING."
  (goto-char
   (org-find-exact-headline-in-buffer
    heading))

  (org-end-of-meta-data)

  (cdr
   (org-list-to-lisp nil)))


(defun roamcrm--current-field
    (heading key)
  "Return KEY from HEADING in current buffer."
  (let
      ((items
        (roamcrm--current-section-items
         heading)))

    (when-let
        ((item
          (seq-find
           (lambda (item)
             (roamcrm--field-item-p
              item
              key))
           items)))

      (roamcrm--field-item-value
       item
       key))))


(defun roamcrm--field
    (file heading key)
  "Return KEY from HEADING in FILE."
  (roamcrm--with-file
   file
   (lambda ()
     (roamcrm--current-field
      heading
      key))))


;;; ============================================================
;;; FIELD DISCOVERY
;;; ============================================================

(defun roamcrm--current-section-fields
    (heading)
  "Return all fields from HEADING.

Return values as `(KEY . VALUE)'."
  (let
      ((items
        (roamcrm--current-section-items
         heading))
       fields)

    (dolist
        (item items)

      (when
          (and
           (consp item)
           (stringp (car item))
           (string-match
            "\\`\\([^:]+\\):[ \t]*\\(.*\\)\\'"
            (car item)))

        (push
         (cons
          (match-string-no-properties 1 (car item))
          (string-trim
           (match-string-no-properties 2 (car item))))
         fields)))

    (nreverse fields)))


(defun roamcrm--section-fields
    (file heading)
  "Return all fields from HEADING in FILE."
  (roamcrm--with-file
   file
   (lambda ()
     (roamcrm--current-section-fields
      heading))))


;;; ============================================================
;;; OUTPUT HELPERS
;;; ============================================================

(defun roamcrm--print-line
    (format-string &rest args)
  "Print one formatted line."
  (princ
   (apply
    #'format
    format-string
    args)))


(defun roamcrm--print-field
    (key value)
  "Print KEY and VALUE."
  (roamcrm--print-line
   "%s: %s\n"
   key
   value))


(defun roamcrm--print-person
    (file)
  "Print one person."
  (roamcrm--print-line
   "%s\t%s\n"
   (roamcrm--file-id file)
   (roamcrm--file-title file)))


;;; ============================================================
;;; CLI: LIST
;;; ============================================================

(defun roamcrm-list ()
  "List all people."
  (dolist
      (file
       (roamcrm--people-files))

    (roamcrm--print-person
     file)))


;;; ============================================================
;;; CLI: RELATIONSHIPS
;;; ============================================================

(defun roamcrm-print-relationship
    (relationship)
  "Print RELATIONSHIP."
  (let
      ((type
        (roamcrm--relationship-type
         relationship))
       (ids
        (roamcrm--relationship-targets
         relationship)))

    (roamcrm--print-line
     "%s:\n"
     type)

    (dolist
        (id ids)

      (roamcrm--print-line
       "  - %s (%s)\n"
       (or
        (roamcrm--title id)
        "UNKNOWN")
       id))))


(defun roamcrm-relationships (input)
  "Print relationships for INPUT."
  (let
      ((file
        (roamcrm--resolve-person input)))

    (unless file
      (error
       "No person found for %s"
       input))

    (roamcrm--print-line
     "Relationships for %s\n\n"
     (roamcrm--file-title file))

    (dolist
        (relationship
         (roamcrm--relationships file))

      (roamcrm-print-relationship
       relationship))))


;;; ============================================================
;;; CLI: BETWEEN
;;; ============================================================

(defun roamcrm-between (input-1 input-2)
  "Print relationships between INPUT-1 and INPUT-2."
  (let*
      ((file-1
        (roamcrm--resolve-person input-1))

       (file-2
        (roamcrm--resolve-person input-2)))

    (unless file-1
      (error
       "No person found for %s"
       input-1))

    (unless file-2
      (error
       "No person found for %s"
       input-2))

    (let*
        ((id-1
          (roamcrm--file-id file-1))

         (id-2
          (roamcrm--file-id file-2))

         (relations
          (roamcrm--relations-between
           file-1
           id-2)))

      (roamcrm--print-line

       "%s → %s: %s\n"

       (roamcrm--file-title file-1)

       (roamcrm--file-title file-2)

       (if relations
           (string-join
            relations
            ", ")

         "No relation found")))))


;;; ============================================================
;;; CLI: GET
;;; ============================================================

(defun roamcrm--require-file
    (input)
  "Resolve INPUT to a file or signal an error."
  (or
   (roamcrm--resolve-file input)

   (error
    "No node found for %s"
    input)))


(defun roamcrm--print-section
    (file section)
  "Print all fields from SECTION in FILE."
  (let
      ((fields
        (roamcrm--section-fields
         file
         section)))

    (if fields

        (dolist
            (field fields)

          (roamcrm--print-field
           (car field)
           (cdr field)))

      (error
       "No fields found in section %s"
       section))))


(defun roamcrm-get
    (input &optional section key)
  "Get information from INPUT.

INPUT may be an ID or title.

With no SECTION or KEY:
  print all fields from Info.

With SECTION but no KEY:
  print all fields from SECTION.

With SECTION and KEY:
  print the value of KEY."
  (let
      ((file
        (roamcrm--require-file input)))

    (cond

     ;; get INPUT
     ((null section)
      (roamcrm--print-section
       file
       "Info"))

     ;; get INPUT SECTION
     ((null key)
      (roamcrm--print-section
       file
       section))

     ;; get INPUT SECTION KEY
     (t
      (let
          ((value
            (roamcrm--field
             file
             section
             key)))

        (if value
            (roamcrm--print-line
             "%s\n"
             value)

          (error
           "Field %s not found in section %s"
           key
           section)))))))


(defun roamcrm-info
    (input &optional key)
  "Get information from Info section."
  (roamcrm-get
   input
   "Info"
   key))


;;; ============================================================
;;; CLI HELP
;;; ============================================================

(defun roamcrm-help ()
  "Print CLI usage."
  (roamcrm--print-line
   "Usage:\n\n")

  (roamcrm--print-line
   "  roamcrm list\n")

  (roamcrm--print-line
   "  roamcrm relationships INPUT\n")

  (roamcrm--print-line
   "  roamcrm between INPUT1 INPUT2\n")

  (roamcrm--print-line
   "  roamcrm get INPUT\n")

  (roamcrm--print-line
   "  roamcrm get INPUT SECTION\n")

  (roamcrm--print-line
   "  roamcrm get INPUT SECTION KEY\n")

  (roamcrm--print-line
   "  roamcrm info INPUT\n")

  (roamcrm--print-line
   "  roamcrm info INPUT KEY\n"))


;;; ============================================================
;;; CLI DISPATCH
;;; ============================================================

(defun roamcrm-command
    (command args)
  "Dispatch COMMAND with ARGS."
  (pcase command

    ("list"
     (roamcrm-list))

    ("relationships"
     (apply
      #'roamcrm-relationships
      args))

    ("between"
     (apply
      #'roamcrm-between
      args))

    ("get"
     (apply
      #'roamcrm-get
      args))

    ("info"
     (apply
      #'roamcrm-info
      args))

    ("help"
     (roamcrm-help))

    (_
     (roamcrm--print-line
      "Unknown command: %s\n\n"
      command)

     (roamcrm-help))))


;;; ============================================================
;;; CLI ENTRYPOINT
;;; ============================================================

(defun roamcrm-cli ()
  "Run roamcrm CLI."
  (let*
      ((args
        (cdr command-line-args-left))

       (command
        (car args))

       (command-args
        (cdr args)))

    (if command

        (roamcrm-command
         command
         command-args)

      (roamcrm-help))))


(roamcrm-cli)
