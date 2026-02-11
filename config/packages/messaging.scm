(define-module (config packages messaging)
#:use-module (guix packages)
#:use-module (guix git-download)
#:use-module (guix build-system cargo)
#:use-module ((guix licenses)
	      #:prefix license:)
#:use-module (guix import crate)
#:use-module (guix utils)
#:use-module (guix gexp)
#:use-module (gnu packages linux)
#:use-module (gnu packages tls)
#:use-module (gnu packages xdisorg)
#:use-module (gnu packages vulkan)
#:use-module (gnu packages freedesktop)
#:use-module (gnu packages xorg)
#:use-module (gnu packages pkg-config)
)

(define-public halloy
  (package
    (name "halloy")
    (version "2025.12")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/squidowl/halloy")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1z5disj4lkg47296j0svmyalfy67h4jqc55w2b73fip6gg9a2mxd"))))
    (build-system cargo-build-system)
    (arguments
     (list
      #:cargo-development-inputs '()
      #:phases
      #~(modify-phases %standard-phases
          (replace 'configure
                   (lambda* (#:key source #:allow-other-keys)
                     (let ((vendor-path (string-append source "/vendor")))
                       (when (file-exists? vendor-path)
                         (setenv "CARGO_HOME" vendor-path))
                       #t)))
          (add-after 'install 'install-desktop-and-icons
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out")))
                ;; Desktop file
                (mkdir-p (string-append out "/share/applications"))
                (call-with-output-file
                    (string-append out
                                   "/share/applications/org.squidowl.halloy.desktop")
                  (lambda (port)
                    (format port
                            "[Desktop Entry]\n\
Name=Halloy\n\
Comment=IRC client written in Rust\n\
Exec=halloy\n\
Icon=org.squidowl.halloy\n\
Terminal=false\n\
Type=Application\n\
Categories=Network;IRCClient;\n\
MimeType=x-scheme-handler/irc;x-scheme-handler/ircs;x-scheme-handler/halloy;\n\
Keywords=IM;Chat;\n\
StartupWMClass=org.squidowl.halloy\n")))
                ;; Icon
                (mkdir-p
                 (string-append out
                                "/share/icons/hicolor/128x128/apps"))
                (install-file
                 "assets/linux/icons/hicolor/128x128/apps/org.squidowl.halloy.png"
                 (string-append out
                                "/share/icons/hicolor/128x128/apps")))))
          (add-after 'install 'patch-rpath-linux
            (lambda* (#:key outputs #:allow-other-keys)
              (when (target-linux?)
                (let* ((out (assoc-ref outputs "out"))
                       (bin (string-append out "/bin/halloy")))
                  ;; Guix usually handles RPATH automatically,
                  ;; but this mirrors the Nix behavior explicitly.
                  (invoke "patchelf"
                          "--set-rpath"
                          (string-append
                           (invoke "patchelf" "--print-rpath" bin)
                           ":"
                           (string-join
                            (list (assoc-ref %build-inputs "wayland")
                                  (assoc-ref %build-inputs "vulkan-loader")
                                  (assoc-ref %build-inputs "libxkbcommon"))
                            ":"))
                          bin))))))))
    (native-inputs
     (list pkg-config))
    (inputs
     (append
      (list openssl)
      (if (target-linux?)
          (list alsa-lib
                libxkbcommon
                vulkan-loader
                wayland
                libx11
                libxcursor
                libxi
                libxcb)
          '())))
    (home-page "https://github.com/squidowl/halloy")
    (synopsis "IRC application")
    (description "Halloy is an IRC client written in Rust.")
    (license license:gpl3+)))

