(define-module (config packages node)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages node)
  #:use-module (gnu packages base)
    #:use-module (gnu packages compression)
  #:use-module ((guix licenses) #:prefix license:)
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
             version
             ".tgz"))
       (sha256
        (base32 "0y5m2f3jlb8qg518gbdbbx0g4s0vn640q9b6vzag1cf7gj239kcq"))))

    (build-system trivial-build-system)
(native-inputs
 (list tar gzip node-lts))
(inputs
 (list tar gzip node-lts))
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))

         (let ((out (assoc-ref %outputs "out"))
               (tarball (assoc-ref %build-inputs "source")))

           (mkdir-p out)

           ;; unpack npm tarball properly
           (invoke "tar" "-xzf" tarball)

           ;; npm tarball extracts into package/
           (copy-recursively "package" (string-append out "/libexec/pnpm"))

           (mkdir-p (string-append out "/bin"))

           ;; create CLI symlinks (THIS WAS MISSING BEFORE)
           (symlink
            (string-append out "/libexec/pnpm/bin/pnpm.cjs")
            (string-append out "/bin/pnpm"))

           (symlink
            (string-append out "/libexec/pnpm/bin/pnpx.cjs")
            (string-append out "/bin/pnpx"))))))

    (home-page "https://pnpm.io/")
    (synopsis "Fast disk space efficient package manager")
    (description "pnpm is a fast package manager for Node.js.")
    (license license:expat)))
