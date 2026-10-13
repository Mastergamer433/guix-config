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
  #:use-module (gnu packages window-management)
  #:use-module (gnu packages haskell)
  #:use-module (gnu packages haskell-xyz)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages music)
  #:use-module (gnu services)
  #:use-module (gnu system)
  #:use-module (gnu system keyboard)
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
  #:use-module (config home services bin)
  #:use-module (config home services foot)
  #:use-module (config home services stumpwm)
  #:use-module (config home services cargo)
  #:use-module (config home services nixpkgs)
  #:use-module (config home services eww)
  #:use-module (config home services hyprland)
  #:use-module (config home services niri-new)
  #:use-module (config home services swaylock)
  #:use-module (config packages hyprland)
  #:use-module (config packages wine-tools)
  #:use-module (config packages flameshot)
  #:use-module (config home services xdg-desktop-portal-hyprland)
  #:use-module (config vars)
  #:use-module (config utils)
  #:use-module (srfi srfi-1)
  #:export (my-home))


(define my-home
  (home-environment
    (packages (list pinentry-qt
                    alacritty
                    font-fira-code
                    direnv
                    eza
                    openssh
                    openjdk21
                    gcc
                    rofi
                    kubectl
                    foot
                    font-nerd-fira-code
                    playerctl
                    ;; bottles
		    flameshot
                    ))

    (services
     (list (service home-kmonad-service-type)
           (service home-spotifyd-service-type)
           (service home-dbus-service-type)
           (service home-pipewire-service-type)
           (service home-emacs-service-type)
           (service home-xdg-desktop-portal-hyprland-service-type)
           (service home-nix-service-type
                    (home-nix-configuration (flake (string-append %config-root
								  "/nix-flake"))
                                            (profile
                                              "$HOME/.local/state/nix/profiles/my-nix")))

           (service home-bin-service-type
                    (home-bin-configuration (programs (list "activate-profile"
							    "update-home"
							    "update-system"))))
           (service home-sway-service-type
                    (sway-configuration (variables `((mod . "Mod4")
                                                     (term . "foot")
                                                     (menu . "wofi --show drun")))
                                        (startup-programs '("eww"))
                                        (keybindings `((´mod-Return . "exec $term")
                                                       ;; switching workspaces and moving containers between workspaces
                                                       ,@(append-map (lambda (n)
                                                                       `((,(string->symbol
                                                                            (format
                                                                             #f
                                                                             "$mod+Shift+~a"
                                                                             n))
                                                                          unquote
                                                                          (format
                                                                           #f
                                                                           "workspace number ~a"
                                                                           n))
                                                                         (,(string->symbol
                                                                            (format
                                                                             #f
                                                                             "$mod+Shfit+~a"
                                                                             n))
                                                                          unquote
                                                                          (format
                                                                           #f
                                                                           "move container to workspace number ~a"
                                                                           n))))

                                                                     (iota 9 1))
                                                       ,@(append-map (lambda (x)
                                                                       `((,(string->symbol
                                                                            (format
                                                                             #f
                                                                             "$mod+~a"
                                                                             (car
                                                                              x)))
                                                                          unquote
                                                                          (format
                                                                           #f
                                                                           "focus ~a"
                                                                           (cdr
                                                                            x)))
                                                                         (,(string->symbol
                                                                            (format
                                                                             #f
                                                                             "$mod+Shift+~a"
                                                                             (car
                                                                              x)))
                                                                          unquote
                                                                          (format
                                                                           #f
                                                                           "move ~a"
                                                                           (cdr
                                                                            x)))))
                                                                     '(("h" . "left")
                                                                       ("j" . "down")
                                                                       ("k" . "up")
                                                                       ("l" . "right")))
                                                       ($mod+q . "kill")
                                                       ($mod+r . "reload")
                                                       ($mod+Shift+e . "exec swaymsg exit")
                                                       ($mod+e . "layout toggle split")))))

					;(service home-niri-service-type
					;(home-niri-configuration
					; (package niri)
					; (extra-packages
					;  (list foot
					;        fuzzel))
					; (data
					;  `(
					;    ("keyboard" . (("layout" . ,(keyboard-layout-name %keyboard-layout))))
					;    ("layout" . (("gaps" . 16)
					;     	    ("border" . (("width" . 4)))))
					;    ("theme" . ,%theme)))))
           (service home-swaylock-service-type
		    (swaylock-configuration
		     (package swaylock-effects)
		     (options
		      `(("timestr" . "%R")
			("datestr" . "%a, %e of %B")
			("fade-in" . "0.2")
			("effect-blur" . "20x2")
			("effect-scale" . "0.3")
			("indicator-radius" . "240")
			("indicator-thickness" . "20")
			("key-hl-color" . ,(color "base08"))
			("separator-color" . ,(string-append (color "base00") "00"))
			("inside-color" . ,(string-append (color "base00") "99"))
			("inside-clear-color" . ,(string-append (color "base0A") "00"))
			("inside-caps-lock-color" . ,(string-append (color "base0C") "00"))
			("inside-ver-color" . ,(string-append (color "base07") "00"))
			("inside-wrong-color" . ,(string-append (color "base08") "00"))
			("ring-color" . ,(string-append (color "base00") "d9"))
			("ring-clear-color" . ,(string-append (color "base00") "d9"))
			("ring-caps-lock-color" . ,(string-append (color "base00") "d9"))
			("ring-ver-color" . ,(string-append (color "base00") "d9"))
			("ring-wrong-color" . ,(string-append (color "base00") "d9"))
			("line-color" . ,(string-append (color "base00") "00"))
			("line-clear-color" . ,(string-append (color "base0A") "ff"))
			("line-caps-lock-color" . ,(string-append (color "base0C") "ff"))
			("line-ver-color" . ,(string-append (color "base07") "ff"))
			("line-wrong-color" . ,(string-append (color "base08") "ff"))
			("text-clear-color" . ,(string-append (color "base0A") "00"))
			("text-ver-color" . ,(string-append (color "base07") "00"))
			("text-wrong-color" . ,(string-append (color "base08") "00"))
			("bs-hl-color" . ,(string-append (color "base08") "ff"))
			("caps-lock-key-hl-color" . ,(string-append (color "base0A") "ff"))
			("caps-lock-bs-hl-color" . ,(string-append (color "base08") "ff"))
			("text-caps-lock-color" . ,(color "base0C"))))
		     (flags
		      '(ignore-empty-password
			clock
			screenshots
			indicator
			indicator-caps-lock
			disable-caps-lock-text))))

	   
	   (service home-niri-service-type
		    (niri-configuration
		     (prefer-no-csd #t)

		     (startup-programs
		      '(("flatpak" "run" "com.discordapp.Discord")
			("librewolf")))

		     (window-rules
		      (list
		       (niri-window-rule
			(match '((app-id . "foot")))
			(tiled-state #t))))

		     (input
		      (niri-input
		       (keyboard-layout
			(keyboard-layout-name %keyboard-layout))))

		     (layout
		      (niri-layout
		       (gaps 8)
		       (background-color (color "base00"))
		       (border
			(niri-border
			 (width 6)
			 (active-color (color "base0D"))
			 (inactive-color (color "base03"))
			 (urgent-color (color "base08"))))
		       (focus-ring
			(niri-focus-ring
			 (off #t)))))

		     (keybindings
		      (append
		       (list
			(niri-bind
			 (key "Mod+Return")
			 (action (niri-spawn "foot")))
			(niri-bind
			 (key "Mod+Q")
			 (action (niri-action 'close-window)))
			(niri-bind
			 (key "Mod+Shift+E")
			 (action (niri-action 'quit)))
			(niri-bind
			 (key "Mod+Escape")
			 (action (niri-action 'toggle-keyboard-shortcuts-inhibit)))
			(niri-bind
			 (key "Mod+T")
			 (action (niri-spawn "swaylock"))))
		       (append-map
			(lambda (x)
			  (let ((key (car x))
				(direction (cdr x))
				(horizontal? (member (car x) '("h" "l"))))
			    (list
			     (niri-bind
			      (key (format #f "Mod+~a" key))
			      (action
			       (niri-action
				(string->symbol
				 (string-append
				  (if horizontal? "focus-column-" "focus-window-")
				  direction))))
			      )
			     (niri-bind
			      (key (format #f "Mod+Shift+~a" key))
			      (action
			       (niri-action
				(string->symbol
				 (string-append
				  (if horizontal? "move-column-" "move-window-")
				  direction))))
			      )
			     (niri-bind
			      (key (format #f "Mod+Ctrl+~a" key))
			      (action
			       (niri-action
				(string->symbol
				 (string-append "focus-monitor-" direction))))
			      )
			     (niri-bind
			      (key (format #f "Mod+Ctrl+Shift+~a" key))
			      (action
			       (niri-action
				(string->symbol
				 (string-append "move-column-to-monitor-" direction))))
			      ))))
			'(("h" . "left")
			  ("j" . "down")
			  ("k" . "up")
			  ("l" . "right")))
		       
		       (append-map
			(lambda (n)
			  (list
			   (niri-bind
			    (key (format #f "Mod+~a" n))
			    (action (niri-action 'focus-workspace n)))
			   (niri-bind
			    (key (format #f "Mod+Ctrl+~a" n))
			    (action (niri-action 'move-column-to-workspace n)))))
			(iota 9 1))))))

           ;; (service home-cargo-service-type)

           
           (service home-eww-service-type)
           
           (service home-foot-service-type)
           
           (service home-hyprland-service-type
                    (home-hyprland-configuration (config my-hypr-config)))

           ;; (service home-nixpkgs-service-type)
           
           ;; (service home-stumpwm-service-type)
           
           (service home-bash-service-type
                    (home-bash-configuration
                      (variables `(("EDITOR" . "emacs -q -nw")
                                   ("PATH" . "~/.bin/:$PATH")))
                      (aliases `(("ls" . "eza")
                                 ;("ssh" . "gpg-connect-agent updatestartuptty /bye >/dev/null && ssh")
                                 ("e" . "$EDITOR")))
                      (bashrc `(,(plain-file "bashrc"
					     "eval \"$(direnv hook bash)\"
export XDG_DATA_DIRS=\"$HOME/.local/share/flatpak/exports/share/:$XDG_DATA_DIRS\"
")))))
           (service home-gpg-agent-service-type
                    (home-gpg-agent-configuration (pinentry-program (file-append
                                                                     pinentry-qt
                                                                     "/bin/pinentry-qt"))
                                                  (ssh-support? #f)))

           ;; (service home-dotfiles-service-type
           ;; (home-dotfiles-configuration
           ;; (source-directory %config-root)
           ;; (directories '("files"))))
           ))))

