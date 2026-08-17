(define-module (config packages node)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages node)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix utils)
  #:use-module (guix download)
  #:use-module (srfi srfi-1))

(define-public pnpm
  (package
    (name "pnpm")
    (version "10.33.1")

    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://registry.npmjs.org/pnpm/-/pnpm-"
             version ".tgz"))
       (sha256
        (base32
         "0y5m2f3jlb8qg518gbdbbx0g4s0vn640q9b6vzag1cf7gj239kcq"))))

    (build-system gnu-build-system)

    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'build)
          (delete 'check)

          (replace 'install
            (lambda _
              (let ((out (assoc-ref %outputs "out")))
                (mkdir-p (string-append out "/libexec/pnpm"))

                (copy-recursively
                 "package"
                 (string-append out "/libexec/pnpm"))

                (mkdir-p (string-append out "/bin"))

                (symlink
                 (string-append out "/libexec/pnpm/bin/pnpm.cjs")
                 (string-append out "/bin/pnpm"))

                (symlink
                 (string-append out "/libexec/pnpm/bin/pnpx.cjs")
                 (string-append out "/bin/pnpx"))))))))

    (inputs
     (list node-lts))

    (home-page "https://pnpm.io/")
    (synopsis "Fast, disk space efficient package manager")
    (description
     "pnpm is a fast, disk space efficient package manager for Node.js.")
    (license license:expat)))
