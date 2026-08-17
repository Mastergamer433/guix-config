(define-module (config packages git)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix licenses)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages ncurses))

(define-public git-quick-stats
  (package
    (name "git-quick-stats")
    (version "2.11.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/git-quick-stats/git-quick-stats/archive/refs/tags/"
             version ".tar.gz"))
       (sha256
        (base32 "0qjm9x8iqhpigi5cna8s7zgq4hyid67cm6rps52wd8a991h2wlkz"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases (modify-phases %standard-phases
                  (delete 'configure)
                  (delete 'build)
                  (delete 'check)
                  (replace 'install
                    (lambda* (#:key inputs outputs #:allow-other-keys)
                      (let* ((out (assoc-ref outputs "out"))
                             (bin (string-append out "/bin")))
                        (install-file "git-quick-stats"
                                      (string-append out "/bin"))

                        (wrap-program (string-append bin "/git-quick-stats")
                          `("PATH" ":" prefix
                            (,(string-append (assoc-ref inputs "ncurses")
                                             "/bin"))))
                        (chmod (string-append bin "/git-quick-stats") #o755)))))))
    (inputs (list ncurses))
    (synopsis
     "Git quick statistics is a simple and efficient way to access various statistics in git repository. ")
    (description
     "Any git repository may contain tons of information about commits, contributors, and files. Extracting this information is not always trivial, mostly because there are a gadzillion options to a gadzillion git commands - I don't think there is a single person alive who knows them all. Probably not even Linus Torvalds himself :).")
    (home-page "https://www.gnu.org/software/hello/")
    (license expat)))
