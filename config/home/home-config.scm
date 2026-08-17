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
  #:use-module (gnu packages music)
  #:use-module (gnu services)
  #:use-module (nongnu packages k8s)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system emacs)
  #:use-module (guix licenses)
  #:use-module (guix gexp)
  #:use-module (config home services kmonad)
  #:use-module (config home services spotifyd)
  #:use-module (config home services emacs)
  #:use-module (config home services nix)
  #:use-module (config packages wlroots)
  #:use-module (config packages hyprland)
  #:use-module (config packages wine-tools)
  #:use-module (config home services xdg-desktop-portal-hyprland)
  #:use-module (config vars)
  #:export (my-home))

(define my-home
  (home-environment
    (packages (list pinentry-qt
                    alacritty
                    sbcl
                    sbcl-slynk
                    stumpwm
                    sbcl-stumpwm-ttf-fonts
                    font-fira-code
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
                    foot
		    eww
		    font-nerd-fira-code
		    playerctl
		    ;bottles
		    ))

    (services
     (list (service home-kmonad-service-type)
           (service home-spotifyd-service-type)
           (service home-sway-service-type)
           (service home-dbus-service-type)
           (service home-pipewire-service-type)
           (service home-emacs-service-type)
	   (service home-xdg-desktop-portal-hyprland-service-type)
	   (service home-nix-service-type
                    (home-nix-configuration
                     (flake (string-append %config-root "/nix-flake"))
                     (profile "$HOME/.local/state/nix/profiles/my-nix")))
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
         (home-dotfiles-configuration
          (source-directory %config-root)
          (directories '("files"))))
	(service home-files-service-type `((".config/hypr" ,(file-append my-hypr-config "/share/hypr"))))))))

