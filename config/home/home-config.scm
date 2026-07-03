(define-module (config home home-config)
  #:use-module (gnu)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services sway)
  #:use-module (gnu home services dotfiles)
  #:use-module (gnu home services desktop)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services sound)
  #:use-module (gnu home services gnupg)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages imagemagick)
  #:use-module (gnu packages terminals)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages shellutils)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages java)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages haskell)
  #:use-module (gnu packages haskell-xyz)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages emacs)
  #:use-module (gnu services)
  #:use-module (nongnu packages k8s)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system emacs)
  #:use-module (guix licenses)
  #:use-module (guix gexp)
  #:use-module (config home services kmonad)
  #:use-module (config packages emacs)
  #:use-module (config packages wlroots)
  #:use-module (config packages hyprland)
  #:export (my-home))

(define my-home
  (home-environment
   (packages (list pinentry-qt
                   alacritty
                   sbcl
		   sbcl-slynk
		   stumpwm
		   sbcl-stumpwm-ttf-fonts
                   emacs-pgtk
		   font-fira-code
                   imagemagick
                   direnv
                   eza
                   openssh
		   openjdk21
		   xmonad
		   ghc
		   ghc-xmonad-contrib
		   ghc-x11
		   gcc
		   rofi
		   kubectl
		   hyprland
		   foot))

   (services
    (list (service home-kmonad-service-type)
          (service home-sway-service-type)
          (service home-dbus-service-type)
	  (service home-pipewire-service-type)
          (service home-bash-service-type
                   (home-bash-configuration
		    (variables `(("EDITOR" . "emacs -q -nw")
				 ("PATH" . "~/.bin/:$PATH")))
                    (aliases `(("ls" . "eza")
			       ("ssh" . "gpg-connect-agent updatestartuptty /bye >/dev/null && ssh")
			       ("e" . "$EDITOR")))
                    (bashrc `(,(plain-file "bashrc"
                                           "eval \"$(direnv hook bash)\"
export GPG_TTY=\"$(tty)\"
unset SSH_AGENT_PID
if [ \"${gnupg_SSH_AUTH_SOCK_by:-0}\" -ne $$ ]; then
    export SSH_AUTH_SOCK=\"$(gpgconf --list-dirs agent-ssh-socket)\"
fi
export XDG_DATA_DIRS=\"$HOME/.local/share/flatpak/exports/share/:$XDG_DATA_DIRS\"
")))))
          (service home-gpg-agent-service-type
                   (home-gpg-agent-configuration (pinentry-program (file-append
                                                                    pinentry-qt
                                                                    "/bin/pinentry-qt"))
                                                 (ssh-support? #t)))
          (service home-dotfiles-service-type
                   (home-dotfiles-configuration (directories '("../../files"))))
	  (service home-files-service-type
		   `((".config/hypr"
		      ,(file-append my-hypr-config "/share/hypr"))))))))

