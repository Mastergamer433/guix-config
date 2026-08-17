(define-module (config packages wine-tools)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix download)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system pyproject)
  #:use-module (gnu packages)
  #:use-module (gnu packages python)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages wine)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-crypto)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages imagemagick)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages graphics)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages build-tools)
  #:use-module (gnu packages pkg-config))

(define-public python-yara
  (package
    (name "python-yara")
    (version "4.5.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "yara-python" version))
       (sha256
        (base32
         "1518cyrjris8idy2wz21n893vgx8yrmdsbl6pj1nqgixnrfgc0a7"))))
    (build-system pyproject-build-system)

    (arguments
     (list
      #:tests? #f)) ; tests may require yara test data

    (native-inputs
     (list python-setuptools
           python-wheel))

    (inputs
     (list yara))

    (home-page
     "https://github.com/VirusTotal/yara-python")
    (synopsis
     "Python bindings for YARA")
    (description
     "yara-python provides Python bindings for the YARA pattern matching
engine.")
    (license license:bsd-3)))

(define-public python-patool
  (package
    (name "python-patool")
    (version "3.1.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "patool" version))
       (sha256
        (base32
         "1518cyrjris8idy2wz21n893vgx8yrmdsbl6pj1nqgixnrfgc0a7"))))
    (build-system pyproject-build-system)
    (native-inputs
     (list python-setuptools
           python-wheel))
    (home-page
     "https://github.com/wummel/patool")
    (synopsis
     "Portable command line archive file manager")
    (description
     "patool is a Python library and command-line tool for creating,
extracting, testing and listing archive files.")
    (license license:gpl3)))

(define-public python-icoextract
  (package
    (name "python-icoextract")
    (version "0.1.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "icoextract" version))
       (sha256
        (base32
         "1518cyrjris8idy2wz21n893vgx8yrmdsbl6pj1nqgixnrfgc0a7"))))
    (build-system pyproject-build-system)
    (propagated-inputs
     (list
      python-pillow
      python-pywin32)) ; see note below
    (native-inputs
     (list python-setuptools
           python-wheel))
    (home-page
     "https://github.com/jlu5/icoextract")
    (synopsis
     "Extract icons from Windows PE files and ICO files")
    (description
     "icoextract extracts icons from Windows executables and ICO files.")
    (license license:expat)))

(define-public bottles
  (package
    (name "bottles")
    (version "64.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/bottlesdevs/Bottles.git")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1518cyrjris8idy2wz21n893vgx8yrmdsbl6pj1nqgixnrfgc0a7"))))

    (build-system meson-build-system)

    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'wrap-python
            (lambda _
              (wrap-program
                  (string-append #$output "/bin/bottles")
                `("PYTHONPATH" ":" prefix
                  (,(getenv "PYTHONPATH")))))))))

    (native-inputs
     (list
      blueprint-compiler
      meson
      ninja
      pkg-config
      wrap-gapps-hook
      appstream-glib
      desktop-file-utils))

    (inputs
     (list
      gtk
      gtksourceview
      libadwaita
      librsvg
      libportal))

    (propagated-inputs
     (list
      python-pyyaml
      python-pycurl
      python-chardet
      python-requests
      python-markdown
      python-icoextract
      python-patool
      python-pathvalidate
      python-orjson
      python-pycairo
      python-pygobject
      python-charset-normalizer
      python-idna
      python-urllib3
      python-certifi
      python-pefile
      python-yara

      cabextract
      p7zip
      xdpyinfo
      imagemagick
      vulkan-tools
      mangohud
      vmtouch
      pciutils
      procps))

    (home-page "https://usebottles.com/")
    (synopsis "Easy-to-use wineprefix manager")
    (description
     "Bottles is a graphical Wine prefix manager.")
    (license license:gpl3)))
