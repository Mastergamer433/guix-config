(define-module (config systems harry-potter)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (gnu system nss)
  #:use-module (gnu services)
  #:use-module (gnu services linux)
  #:use-module (gnu services desktop)
  #:use-module (gnu services xorg)
  #:use-module (gnu services networking)
  #:use-module (gnu services ssh)
  #:use-module (gnu services lightdm)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services nix)
  #:use-module (gnu services docker)
  #:use-module (gnu services containers)
  #:use-module (gnu services guix)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages vim)
  #:use-module (gnu packages xfce)
  #:use-module (gnu packages terminals)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages package-management)
  #:use-module (nongnu packages nvidia)
  #:use-module (nonguix transformations)
  #:use-module (nongnu system linux-initrd)
  #:use-module (nongnu packages linux)
  #:use-module (config systems base-system)
;  #:use-module (config systems containers)
  #:use-module (config packages nvidia)
  #:use-module (config home home-config))

(define secrets-path
  "../../secrets")

;; (define build01-private-key
;;   (sops-secret
;;    (key '("build01"))
;;    (file (local-file (file-append secrets-path "build-machines.yaml")))))

(define %my-os
  (operating-system
    (inherit %base-system)
    (host-name "harry-potter")
    (timezone "Europe/Stockholm")
    (locale "en_US.utf8")

    (keyboard-layout (keyboard-layout "se"))

    (kernel linux)
    (initrd microcode-initrd)
    (firmware (list linux-firmware))

    (initrd-modules (append '("dm-crypt" "sha256" "btrfs")
                            %base-initrd-modules))

    (users (cons (user-account
                   (name "mg433")
                   (group "users")
                   (home-directory "/home/mg433")
                   (password (crypt "InitialPassword!" "$6$abc"))
                   (supplementary-groups '("wheel" "netdev" "audio" "video")))
                 %base-user-accounts))
    (packages (append (list flatpak
                            ;; nvidia-container-toolkit
                            stumpwm xmonad hyprland) %my-base-packages))
    (services
     (append %base-services
             (list (service nix-service-type
                            (nix-configuration (extra-config '("extra-experimental-features = nix-command flakes"))))
                   (service iwd-service-type)
                   ;; (service docker-service-type
                   ;; (docker-configuration
                   ;; (config-file (local-file "files/daemon.json"))))
                   (service docker-service-type)
                   (service containerd-service-type)
                   ;; (service sops-secrets-service-type
                   ;; (sops-service-configuration
                   ;; (secrets (list build01-private-key))))
                   ;; (service guix-service-type
                   ;; (guix-configuration
                   ;; (build-machines
                   ;; (list
                   ;; (build-machine
                   ;; (name "guix-build01.selud02.kimane.se")
                   ;; (system "x86_64-linux")
                   ;; (host-key "TODO")
                   ;; (user "guix")
                   ;; (speed 2)
                   ;; (private-key))))))
                   (service network-manager-service-type)
                   (service elogind-service-type)
                   ;; (service seatd-service-type)
                   ;; (service xorg-server-service-type
                   ;; (xorg-configuration (keyboard-layout
                   ;; keyboard-layout)))
                   (simple-service 'oci-provisioning oci-service-type
                                   (oci-extension (containers (list ;bitlbee-container
								    (oci-container-configuration
                                                                     (image
                                                                      "ollama/ollama")
                                                                     (ports '(("11434" . "11434")))
                                                                     (volumes '
                                                                              ("ollama:/root/.ollama")))))))
                   (service guix-home-service-type
                            `(("mg433" ,my-home))))))

    (name-service-switch %mdns-host-lookup-nss)

    (bootloader (bootloader-configuration
                  (bootloader grub-efi-bootloader)
                  (targets '("/efi"))))
    (mapped-devices (list (mapped-device
                            (source (uuid
                                     "0b88f4ac-70ed-442b-b43e-ffd703b9cf8d"))
                            (target "root")
                            (type luks-device-mapping))))
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device "/dev/mapper/root")
                           (type "btrfs")
                           (options "subvol=guix/@,compress=zstd,ssd")
                           (needed-for-boot? #t)
                           (dependencies mapped-devices))
                         (file-system
                           (mount-point "/boot")
                           (device (uuid
                                    "69ddab2e-2c16-4b3a-8d6a-288babc26329"))
                           (type "btrfs")
                           (options "subvol=guix,ssd"))
                         (file-system
                           (mount-point "/efi")
                           (device (uuid "ea94-c17f"
                                         'fat))
                           (type "vfat")) %base-file-systems))))

((nonguix-transformation-nvidia)
 %my-os)
