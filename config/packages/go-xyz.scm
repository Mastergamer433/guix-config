(define-module (config packages go-xyz)
	       #:use-module (guix packages)
	       #:use-module (guix git-download)
	       #:use-module (guix build-system go)
	       #:use-module ((guix licenses)
                #:prefix license:)
	       #:use-module (gnu packages golang-xyz))

(define-public go-github-com-bluebrown-go-template-cli
  (package
    (name "go-github-com-bluebrown-go-template-cli")
    (version "0.3.2")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/bluebrown/go-template-cli")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1r1mwk3qz8c46z9q4qkmm40mjxk9ancph70wd12vk8hkf3ak0r2d"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/bluebrown/go-template-cli/cmd/tpl"
      #:unpack-path "github.com/bluebrown/go-template-cli/"
      #:install-source? #f))
    (propagated-inputs (list go-github-com-burntsushi-toml
                             go-github-com-masterminds-sprig-v3
                             go-github-com-spf13-pflag go-gopkg-in-yaml-v3))
    (home-page "https://github.com/bluebrown/go-template-cli")
    (synopsis "Go Template CLI (tpl)")
    (description
     "Render json, yaml, & toml with go templates from the command line.")
    (license license:bsd-0)))

