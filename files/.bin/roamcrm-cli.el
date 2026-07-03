;;; =========================
;;; SETUP
;;; =========================

(setq package-user-dir (expand-file-name "~/roamcrm-cli-packages/"))

(require 'package)

(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))

(setq inhibit-message t)

(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(dolist (pkg '(org org-roam))
  (unless (package-installed-p pkg)
    (package-install pkg)))

(setq org-roam-directory (expand-file-name "~/notes/"))
(org-roam-db-autosync-mode)

;;; =========================
;;; CORE HELPERS
;;; =========================

(defun roamcrm--all-nodes ()
  (org-roam-node-list))

(defun roamcrm--people ()
  (seq-filter
   (lambda (n)
     (member "person" (org-roam-node-tags n)))
   (roamcrm--all-nodes)))

(defun roamcrm--node-id (node)
  (org-roam-node-id node))

(defun roamcrm--node-title (node)
  (org-roam-node-title node))

(defun roamcrm--find-by-id (id)
  (seq-find
   (lambda (n)
     (string= (roamcrm--node-id n) id))
   (roamcrm--all-nodes)))

(defun roamcrm--find-by-title (title)
  (seq-find
   (lambda (n)
     (string= (roamcrm--node-title n) title))
   (roamcrm--all-nodes)))

(defun roamcrm--resolve-node (input)
  "Resolve INPUT as ID or title."
  (or (roamcrm--find-by-id input)
      (roamcrm--find-by-title input)))

(defun roamcrm--title (id)
  (when-let ((n (roamcrm--find-by-id id)))
    (roamcrm--node-title n)))

;;; =========================
;;; BUFFER / FILE UTIL
;;; =========================

(defmacro roamcrm--with-node-buffer (node &rest body)
  `(with-current-buffer (find-file-noselect (org-roam-node-file ,node))
     (save-excursion
       (goto-char (point-min))
       ,@body)))

;;; =========================
;;; RELATIONSHIP LAYER
;;; =========================

(defun roamcrm--parse-rel-line ()
  (cons (match-string 1)
        (split-string (match-string 2) " " t)))

(defun roamcrm--relationships (node)
  "Return ((type . (ids...)) ...)"
  (roamcrm--with-node-buffer node
    (let (out)
      (while (re-search-forward "^:REL_\\([^:]+\\):[ \t]+\\(.+\\)$" nil t)
        (push (roamcrm--parse-rel-line) out))
      out)))

(defun roamcrm--relations-between (node target-id)
  (let (found)
    (dolist (r (roamcrm--relationships node))
      (when (member target-id (cdr r))
        (push (car r) found)))
    found))

;;; =========================
;;; FIELD PARSER
;;; =========================
(defun roamcrm--field (node heading key)
  "Get KEY from SECTION in NODE."
  (roamcrm--with-node-buffer node
   (goto-char (org-find-exact-headline-in-buffer heading))
   (org-end-of-meta-data)
   (let ((fields (cdr (org-list-to-lisp nil))))
     (string-trim
   	(substring
   	 (car (seq-find (lambda (x)
   			  (string-prefix-p (concat key ":") (car x)))
   			fields))
   	 (1+ (length key)))))))

;;; =========================
;;; CLI COMMANDS
;;; =========================

(defun roamcrm-list ()
  (dolist (n (roamcrm--people))
    (princ (format "%s\t%s\n"
                   (roamcrm--node-id n)
                   (roamcrm--node-title n)))))

(defun roamcrm-relationships (input)
  (let ((node (roamcrm--resolve-node input)))
    (unless node
      (error "No node found for %s" input))

    (princ (format "Relationships for %s\n\n"
                   (roamcrm--node-title node)))

    (dolist (r (roamcrm--relationships node))
      (princ (format "%s:\n" (car r)))
      (dolist (id (cdr r))
        (princ (format "  - %s (%s)\n"
                       (or (roamcrm--title id) "UNKNOWN")
                       id))))))

(defun roamcrm-between (id1 id2)
  (let* ((node (roamcrm--resolve-node id1))
         (target-id (if (roamcrm--find-by-id id2)
                        id2
                      (roamcrm--node-id
                       (roamcrm--find-by-title id2))))
         (rels (roamcrm--relations-between node target-id)))

    (princ
     (if rels
         (format "%s → %s: %s\n"
                 (roamcrm--node-title node)
                 (roamcrm--title target-id)
                 (string-join rels ", "))
       "No relation found\n"))))

(defun roamcrm-get (input section key)
  "Get KEY from SECTION of INPUT node (id or title)."
  (let ((node (roamcrm--resolve-node input)))
    (unless node
      (error "No node found for %s" input))

    (princ (concat (roamcrm--field node section key) "\n"))))

(defun roamcrm-info (input key)
  "Get KEY from Info section of INPUT node."
  (roamcrm-get input "Info" key))

;;; =========================
;;; CLI ENTRYPOINT
;;; =========================

(defun roamcrm-cli ()
  (let ((args (cdr command-line-args-left)))
    (pcase (car args)
      ("list"
       (roamcrm-list))

      ("relationships"
       (apply #'roamcrm-relationships (cdr args)))

      ("between"
       (apply #'roamcrm-between (cdr args)))

      ("get"
       (apply #'roamcrm-get (cdr args)))
      
      ("info"
       (apply #'roamcrm-info (cdr args)))

      (_
       (princ (format "Unknown command: %S\n" args))))))

(roamcrm-cli)
