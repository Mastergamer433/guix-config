(define-module (config systems base-system)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages vim)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages curl)
  #:export (%base-system %my-base-packages))

(define %my-base-packages
  (append (list emacs vim git wget curl) %base-packages))
(define %base-system
  (operating-system
    (host-name "base-system")
    (timezone "Etc/UTC")
    (locale "en_US.utf8")
    (keyboard-layout (keyboard-layout "us" "altgr-intl"))

    (packages %my-base-packages)
    ;; Guix doesn't like it when there isn't a file-systems
    ;; entry, so add one that is meant to be overridden
    (file-systems (cons* (file-system
                           (mount-point "/tmp")
                           (device "none")
                           (type "tmpfs")
                           (check? #f)) %base-file-systems))
    ;; Neither does it like it when there is no bootloader
    ;; entry, so add one that also is meant to be overridden
    (bootloader (bootloader-configuration
                  (bootloader grub-efi-bootloader)
                  (targets '("/efi"))))))
