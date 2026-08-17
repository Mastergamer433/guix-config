(define-module (config packages fluxer-desktop)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses)
		#:prefix license:)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module (gnu packages)
  #:use-module (gnu packages node)
  #:use-module (gnu packages python)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages web)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages linux)
  
  
  #:use-module (nongnu packages electron)
  #:use-module (config packages node)
  #:export (fluxer-desktop))

(define-public fluxer-desktop
  (package
            (name "fluxer-desktop")
    (version "2026.813.222222")

    ;; Replace this with the actual Fluxer repository and commit.
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/fluxerapp/fluxer")
             (commit version)))
;       (file-name (git-file-name name version))
       (sha256
        (base32 "0gxhmzdav66805i33ggwdalkwinq7a8vi6p4nyk5hkh1jsgqjrd7"))))

    (build-system gnu-build-system)

    (arguments
     (list
      #:tests? #f

      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)

          (add-after 'unpack 'enter-desktop
            (lambda _
              (chdir "fluxer_desktop")))

          (replace 'build
            (lambda _
              ;; The Nix package uses pnpm's frozen lockfile install.
              ;; At this point the dependency tree must already have been
              ;; populated by the Guix package.
              (setenv "NODE_ENV" "production")
              (setenv "FLUXER_DESKTOP_PRODUCTION" "true")

              ;; Don't allow Electron Builder to download Electron.
              (setenv "ELECTRON_SKIP_BINARY_DOWNLOAD" "1")

              (invoke "pnpm" "run" "set-channel" "stable")
              (invoke "pnpm" "build")

              (invoke
               "pnpm" "exec" "electron-builder"
               "--config" "electron-builder.config.cjs"
               "--linux"
               "--dir"
               (string-append
                "-c.electronDist="
                #$(this-package-input "electron")
                "/libexec/electron")
               (string-append
                "-c.electronVersion="
                #$(package-version
                   (this-package-input "electron")))
               "-c.npmRebuild=false")))

          (replace 'install
            (lambda _
              (let ((out (assoc-ref %outputs "out"))
                    (electron #$(this-package-input "electron")))

                (mkdir-p
                 (string-append out "/share/fluxer"))

                (copy-recursively
                 "dist-electron/linux-unpacked/resources"
                 (string-append out "/share/fluxer/resources"))

                ;; electron-builder's --dir output puts the executable
                ;; alongside resources. We don't use that Electron binary;
                ;; Guix supplies Electron itself.
                (mkdir-p (string-append out "/bin"))

                (make-file-writable
                 (string-append out "/bin/fluxer"))

                (call-with-output-file
                    (string-append out "/bin/fluxer")
                  (lambda (port)
                    (format
                     port
                     "#!/bin/sh~@
                      exec ~a/bin/electron \"$@\"~%"
                     electron)))

                (chmod
                 (string-append out "/bin/fluxer")
                 #o755)))))))

    (native-inputs
     (list
      node
      pnpm
      python
      esbuild))

    (inputs
     (list
      electron

      glib
      nspr
      nss
      dbus
      at-spi2-core
      cups
      cairo
      gtk+
      pango
      libx11
      libxcomposite
      libxdamage
      libxext
      libxtst
      libxt
      libxfixes
      libxrandr
      mesa
      expat
      libxcb
      libxkbcommon
      eudev
      alsa-lib))

    (home-page "https://fluxer.app")
    (synopsis "Fluxer desktop client")
    (description
     "Fluxer is an open-source instant messaging and VoIP application.")
    (license license:agpl3+)))


