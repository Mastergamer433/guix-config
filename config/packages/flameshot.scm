(define-module (config packages flameshot)
	       #:use-module (guix packages)
	       #:use-module (guix gexp)
	       #:use-module (guix git-download)
	       #:use-module (guix build-system qt)
	       #:use-module ((guix licenses)
                #:prefix license:)
	       #:use-module (gnu packages golang-xyz)
	       #:use-module (gnu packages qt)
	       #:use-module (gnu packages kde-frameworks)
	       )


(define-public flameshot
  (package
    (name "flameshot")
    (version "13.3.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
              (url "https://github.com/flameshot-org/flameshot")
              (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1v9xsivq9wnj7x1gr877a40xi6j672h9j82c5nkih9b64jg0naj7"))))
    (build-system qt-build-system)
    (arguments
     (list
      #:qtbase qtbase
      #:tests? #f                     ;no tests
      #:configure-flags
      #~(list "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
              "-DUSE_BUNDLED_KDSINGLEAPPLICATION=OFF"
	      "-DUSE_WAYLAND_CLIPBOARD=ON"
              "-DDISABLE_UPDATE_CHECKER=ON")))
    (native-inputs (list qttools))
    (inputs (list kdsingleapplication qtcolorwidgets qtsvg kguiaddons))
    (home-page "https://github.com/flameshot-org/flameshot")
    (synopsis "Powerful yet simple to use screenshot software")
    (description "Flameshot is a screenshot program.
Features:

@itemize
@item Customizable appearance.
@item Easy to use.
@item In-app screenshot edition.
@item DBus interface.
@item Upload to Imgur.
@end itemize\n")
    (license license:gpl3+)))
