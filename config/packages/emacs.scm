(define-module (config packages emacs)
  #:use-module (guix packages)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages imagemagick)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix git-download)
  #:use-module (guix build-system cargo)
  #:use-module (guix gexp)
  #:use-module (config packages rust-crates)
  #:export (emacs-with-imagemagick))

(define-public emacs-with-imagemagick
  (package
    (inherit emacs)
    ;; Add ImageMagick to inputs
    (inputs (cons `("imagemagick" ,imagemagick)
                  (package-inputs emacs)))
    ;; Modify arguments to append "--with-imagemagick"
    (arguments
     (let ((args (package-arguments emacs)))
       (map (lambda (arg)
              (if (and (pair? arg)
                       (eq? (car arg)
                            '#:configure-flags))
                  ;; Append to existing configure flags
                  (cons '#:configure-flags
                        (append (cdr arg)
                                '("--with-imagemagick"))) arg)) args)))))

(define-public ewm
  (package
    (name "ewm")
    (version "0.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://codeberg.org/ezemtsov/ewm")
             (commit "43f6b5ec82b336aef1acf0f78a016ba909a62b4d")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "08kksg50nmnfzc8hl8bxzm40j6p2x5niyz0s4xj99hrkv8vz8520"))))

    (build-system cargo-build-system)
    (inputs (cargo-inputs 'ewm-core
                          #:module '(config packages rust-crates)))
    ;; (inputs (list emacs))
    (arguments
     (list
      #:install-source? #f
      #:features '(list "screencast")

      #:phases
      #~(modify-phases %standard-phases
          
          ;; Build happens in compositor/
          (add-before 'build 'enter-compositor
            (lambda _
              (chdir "compositor")))

          ;; Install the shared library
          (add-after 'install 'install-module
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (moddir (string-append out "/lib/emacs/modules")))
                (mkdir-p moddir)
                (copy-file "target/release/libewm_core.so"
                           (string-append moddir "/libewm_core.so")))))

          ;; Install Lisp
          (add-after 'install-module 'install-lisp
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (lispdir (string-append out "/share/emacs/site-lisp/ewm")))
                (mkdir-p lispdir)
                (copy-recursively "../../lisp" lispdir)))))))

    (home-page "https://github.com/.../ewm")
    (synopsis "Wayland compositor module for Emacs")
    (description
     "EWM is a Wayland compositor implemented as an Emacs dynamic module.")
    (license license:gpl3+)))
