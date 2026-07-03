(define-module (config packages fluxer-desktop)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system node)
  #:use-module (guix licenses)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module (gnu packages)
  #:use-module (gnu packages node)
  #:use-module (gnu packages python)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (nongnu packages electron)
  #:use-module (config packages node)
  #:export (fluxer-desktop))

(define fluxer-desktop
  (package
   (name "fluxer-desktop")
   (version "0.0.8-unstable-2026-03-06")
   (source
    (origin
     (method git-fetch)
     (uri (git-reference
           (url "https://github.com/fluxerapp/fluxer")
           (commit "03813bbe17db008452f0f1be3090a7d2970a5447")))
     (file-name (git-file-name name version))
     (sha256
      (base32 "0mj19dbnb8xjrvr6azvvz1sns2cpafwg9dllr1vsv831a8xpbi87"))
     (patches
      (list "config/config/packages/fluxer-desktop/electron-builder-config.patch"))))

   (build-system node-build-system)

   (inputs
    (list electron
          node
          python
          libx11
          libxrandr
          libxtst
          libxt
	  	  (local-file
           "config/config/packages/fluxer-desktop/pnpm-store.tar.zst")))

   (native-inputs
    (list node
          python
          tar
          gzip
	  (local-file
           "config/config/packages/fluxer-desktop/pnpm-store.tar.zst")
	  pnpm
	  ))

   (arguments
    '(
      #:modules ((guix build node-build-system)
                 (guix build utils)
                 (srfi srfi-26))
		#:phases
		(modify-phases %standard-phases
			       (add-after 'unpack 'restore-pnpm-store
					  (lambda* (#:key inputs #:allow-other-keys)
						   (for-each
						    (lambda (input)
						      (when (string-contains (car input) "pnpm-store")
							(invoke "tar" "--zstd" "-xf" (cdr input))
							(setenv "PNPM_STORE_PATH"
								(string-append (getcwd) "/store"))))
						    inputs)))
			       (replace 'configure
					(lambda _
					  (invoke "pnpm" "install"
						  "--frozen-lockfile"
						  "--offline"
						  "--ignore-scripts")))
			       (add-before 'build 'set-production
					   (lambda _
					     (setenv "NODE_ENV" "production")))

			       (replace 'build
					(lambda _
					  (invoke "pnpm" "install"
						  "--frozen-lockfile"
						  "--offline"
						  "--ignore-scripts")

					  (invoke "pnpm" "build")

					  (copy-recursively
					   (string-append #$electron "/libexec/electron")
					   "electron-dist")

					  (chmod "electron-dist" #o755)

					  (setenv "npm_config_nodedir"
						  (string-append #$electron "/include/node"))

					  (invoke "pnpm" "exec" "electron-builder"
						  "--config" "electron-builder.config.cjs"
						  "--dir"
						  "-c.electronDist=electron-dist"
						  (string-append "-c.electronVersion=" #$electron-version)
						  "-c.extraMetadata.name=app.fluxer.Fluxer"
						  (string-append "-c.extraMetadata.version=" #$version)
						  "-c.mac.identity=null")))

			       (replace 'install
					(lambda _
					  (let* ((out (assoc-ref %outputs "out"))
						 (app "app.fluxer.Fluxer"))

					    (mkdir-p (string-append out "/share/" app))
					    (mkdir-p (string-append out "/bin"))

					    (copy-recursively
					     "dist-electron/linux-unpacked/resources"
					     (string-append out "/share/" app))

					    (let ((bin (string-append out "/bin/fluxer-desktop")))
					      (call-with-output-file bin
						(lambda (p)
						  (format p "#!~a\nexec ~a \"$@\"\n"
							  (which "sh")
							  (string-append #$electron "/bin/electron")
							  (string-append out "/share/" app "/app.asar"))))
					      (chmod bin #o755))))))))

   (home-page "https://fluxer.app/")
   (synopsis "Instant messaging and VoIP platform")
   (description
    "Free and open source instant messaging and VoIP platform built for friends, groups, and communities.")
   (license agpl3+)
   (supported-systems '("x86_64-linux" "aarch64-linux" "x86_64-darwin"))))
