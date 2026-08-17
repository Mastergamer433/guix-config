(define-module (config packages rust-sources)
  #:use-module (guix git-download)
  #:use-module (guix build-system cargo)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix build utils)
  #:use-module (guix gexp))

(define-public rust-smithay-0.7.0.ae14fa1
  (let ((commit "ae14fa12f6ee3fc4dd4c766ffb21848f991a6a18")
        (revision "0"))
    (package
      (name "rust-smithay")
      (version (git-version "0.7.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/Smithay/smithay.git")
               (commit "ae14fa12f6ee3fc4dd4c766ffb21848f991a6a18")))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0a56387p9s5qsy7m9br63frssswbfjgyiwmwf1msj7lq56ms0bq7"))))
      (build-system cargo-build-system)
      (arguments
       (list
        #:skip-build? #t
        #:cargo-package-crates ''("smithay" "smithay-drm-extras" "smallvil"
                                  "anvil" "wlcs_anvil" "test_clients")
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'patch-smallvil-cargo-toml
              (lambda _
                (display
                 "Patching smallvil/Cargo.toml to replace local path dependency...
")
                (substitute* "smallvil/Cargo.toml"
                  ;; Replace path = "../" with crates.io version
                  (("path *= *\"../\"")
                   "version = \"0.7.0\""))
                (substitute* "anvil/Cargo.toml"
                  ;; Replace path = "../" with crates.io version
                  (("path *= *\"..\"")
                   "version = \"0.7.0\""))
                (substitute* "smithay-drm-extras/Cargo.toml"
                  ;; Replace path = "../" with crates.io version
                  (("path *= *\"../\"")
                   "version = \"0.7.0\"")
                  (("smithay-drm-extras *= *\\{ *path *= *\"../smithay-drm-extras\" *, *optional *= *true *\\}")
                   "smithay-drm-extras = { version = \"0.7.0\", optional = true }"))
                #t)))))
      (inputs (cargo-inputs 'rust-smithay-0.7.0.ae14fa1
                            #:module '(config packages rust-crates)))
      (home-page "https://crates.io/crates/smithay")
      (synopsis "Rust package Smithay")
      (description "This package provides the rust crate smithay.")
      (license license:expat))))
