(define-module (config packages kubevirt)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system go)
  #:use-module (guix licenses)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:export (kubevirt-virtctl))

(define kubevirt-virtctl
  (package
    (name "kubevirt")
    (version "1.6.3")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/kubevirt/kubevirt")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0n6yp7xz0kw00r8hi454vhqyvj207nwx36plr64c7b9iw4632c2w"))))
    (build-system go-build-system)

    ;; Go module main package
    (arguments
     (list
      #:import-path "kubevirt.io/kubevirt/cmd/virtctl"
      #:build-flags
      #~(list "-tags=selinux"
              (string-append "-ldflags="
               "-X kubevirt.io/client-go/version.gitCommit=v"
               #$version
               " "
               "-X kubevirt.io/client-go/version.gitTreeState=clean "
               "-X kubevirt.io/client-go/version.gitVersion=v"
               #$version))

      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-shell-completions
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin/virtctl")))
                (when (file-exists? bin)
                  ;; Bash
                  (with-output-to-file "virtctl.bash"
                    (lambda ()
                      (invoke bin "completion" "bash")))
                  (install-file "virtctl.bash"
                                (string-append out
                                 "/share/bash-completion/completions/"))

                  ;; Fish
                  (with-output-to-file "virtctl.fish"
                    (lambda ()
                      (invoke bin "completion" "fish")))
                  (install-file "virtctl.fish"
                                (string-append out
                                 "/share/fish/vendor_completions.d/"))

                  ;; Zsh
                  (with-output-to-file "_virtctl"
                    (lambda ()
                      (invoke bin "completion" "zsh")))
                  (install-file "_virtctl"
                                (string-append out
                                               "/share/zsh/site-functions/")))))))))

    (native-inputs (list))

    (home-page "https://kubevirt.io/")
    (synopsis "Client tool for KubeVirt advanced features (virtctl)")
    (description
     "virtctl is a client tool for KubeVirt that provides advanced VM
management features such as console access.")
    (license asl2.0)))
