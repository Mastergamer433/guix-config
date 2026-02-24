(define-module (config home home-config)
  #:use-module (gnu)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services sway)
  #:use-module (gnu home services dotfiles)
  #:use-module (gnu home services desktop)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services gnupg)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages imagemagick)
  #:use-module (gnu packages terminals)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages shellutils)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages ssh)
  #:use-module (gnu services)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system emacs)
  #:use-module (guix licenses)
  #:use-module (guix gexp)
  #:use-module (config home services kmonad)
  #:use-module (config packages emacs))

(home-environment
  (packages (list pinentry-qt
                  alacritty
                  sbcl
                  emacs-with-imagemagick
                  font-fira-code
                  imagemagick
                  direnv
                  eza
                  openssh))
  (services
   (list (service home-kmonad-service-type)
         (service home-sway-service-type)
         (service home-dbus-service-type)
         (service home-bash-service-type
                  (home-bash-configuration
                   (aliases `(("ls" . "eza")))
                   (bashrc `(,(plain-file "bashrc"
                                          "eval \"$(direnv hook bash)\"")))))
         (service home-gpg-agent-service-type
                  (home-gpg-agent-configuration (pinentry-program (file-append
                                                                   pinentry-qt
                                                                   "/bin/pinentry-qt"))
                                                (ssh-support? #t)))
         (service home-dotfiles-service-type
                  (home-dotfiles-configuration (directories '("../../files")))))))

