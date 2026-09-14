(define-module (config packages hyprland)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system cmake)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages window-management)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages build-tools)
)

(define-public my-hypr-config
  (package
    (name "my-hypr-config")
    (version "0.1")
    (source
     (local-file "./hypr-config"
                 #:recursive? #t))
    (build-system gnu-build-system)
    (native-inputs (list fennel))
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)

          (replace 'build
            (lambda _
              (use-modules (guix build utils)
                           (ice-9 ftw)
                           (srfi srfi-1))

              (define (strip-prefix path prefix)
                (if (string-prefix? prefix path)
                    (substring path
                               (string-length prefix)) path))

              (define (fnl->lua path)
                (let* ((no-prefix (strip-prefix path "./src/"))
                       (no-ext (string-drop-right no-prefix 4)))
                  (string-append "build/" no-ext ".lua")))

              (mkdir-p "build")

              (for-each (lambda (file)
                          (when (string-suffix? ".fnl" file)
                            (let* ((out (fnl->lua file)))
                              (mkdir-p (dirname out))

                              (with-output-to-file out
                                (lambda ()
                                  (invoke "fennel" "--compile" file))))))
                        (find-files "." "\\.fnl$"))))

          (replace 'install
            (lambda _
              (use-modules (guix build utils))
              (let ((out (string-append #$output "/share/hypr")))
                (mkdir-p out)
                (copy-recursively "build" out)))))))

    (synopsis "My Hyprland configuration")
    (description "My Hyprland config")
    (home-page "")
    (license #f)))

;(define-public hyprland-for-plugins
;  (package
;    (inherit hyprland)
;
;    (outputs
;     (list "out" "dev"))
;
;    (arguments
;     (substitute-keyword-arguments (package-arguments hyprland)
;       ((#:configure-flags flags #~'())
;        #~(cons*
;            (string-append
;             "-DCMAKE_INSTALL_INCLUDEDIR="
;             #$output:dev
;             "/include")
;            (string-append
;             "-DCMAKE_INSTALL_LIBDIR="
;             #$output:out
;             "/lib")
;            #$flags))))))
;
;(define-public hyprland-plugin-hy3
;  (package
;    (name "hyprland-plugin-hy3")
;    (version "0.1")
;        (source
;     (origin
;       (method git-fetch)
;       (uri (git-reference
;             (url "https://github.com/outfoxxed/hy3")
;             (commit "ded5e168f3a8d1290b34d696930098e8c141404d")))
;       (sha256 (base32 "06yd8jzqgrdjlxryjpgcb5vg71v1g0c19bajkcq4mbssizfxhqpa"))))
;
;    (build-system cmake-build-system)
;
;    (arguments
;     (list
;      #:configure-flags
;      #~(list "-DCMAKE_BUILD_TYPE=RelWithDebInfo" "-DHY3_NO_VERSION_CHECK=OFF")))
;
;    (native-inputs
;     (list ninja
;           pkg-config))
;(inputs
; (list `(,hyprland-for-plugins "dev")
;       hyprcursor
;       hyprgraphics
;       hyprlang
;       hyprutils
;       aquamarine
;       mesa
;       xcb-util-wm
;       xcb-util-errors
;       lua
;       glslang
;       libdrm
;       libinput
;       wayland
;       libxkbcommon
;       pixman
;       pango
;       cairo))
;
;    (synopsis "Hyprland plugin for an i3-like manual tiling layout")
;    (description
;     "Hyprland plugin for an i3-like manual tiling layout.")
;    (home-page "https://github.com/outfoxxed/hy3")
;    (license license:gpl3+)))
