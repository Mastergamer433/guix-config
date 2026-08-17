(define-module (config home services hyprland)
  #:use-module (gnu packages)
  #:use-module (gnu packages linux)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix build utils)
  #:use-module (config packages hyprland)
  #:export (home-hyprland-service-type))

;; ----------------------------
;; Configuration record
;; ----------------------------

(define-configuration/no-serialization home-hyprland-service-configuration
  (hyprland
   (package hyprland)
   "Hyprland package to use.")

  (config
   (package my-hypr-config)
   "Package containing the user's Hyprland configuration.")

  (plugins
   (list '())
   "List of Hyprland plugin packages."))

;; ----------------------------
;; Plugin -> Lua loader
;; ----------------------------

(define (plugin->so-path plugin)
  (string-append
   plugin "/lib/lib"
   (package-name plugin)
   ".so"))

(define (plugins->lua plugins)
  (mixed-text-file
   "plugins.lua"
   (append-map
    (lambda (plugin)
      (list
       "hl.plugin.load(\""
       (plugin->so-path plugin)
       "\")\n"))
    plugins)))

;; ----------------------------
;; Profile packages
;; ----------------------------

(define (hyprland-profile config)
  (append
   (list
    (home-hyprland-service-configuration-hyprland config))
   (home-hyprland-service-configuration-plugins config)))

;; ----------------------------
;; Build final ~/.config/hypr
;; ----------------------------

(define (hypr-config-directory config)
  (let ((base-config (home-hyprland-service-configuration-config config))
        (plugins     (home-hyprland-service-configuration-plugins config)))

    (computed-file
     "hypr-config"

     #~(begin
         (use-modules (guix build utils))

         ;; copy your fennel-compiled config
         (copy-recursively
          (string-append #$base-config "/share/hypr")
          #$output)

         ;; add generated plugin loader
         (copy-file
          #$(plugins->lua plugins)
          (string-append #$output "/plugins.lua"))))))

;; ----------------------------
;; Home files service
;; ----------------------------

(define (hyprland-files config)
  `(("config/hypr"
     ,(hypr-config-directory config))))

;; ----------------------------
;; Service type
;; ----------------------------

(define home-hyprland-service-type
  (service-type
   (name 'home-hyprland)

   (extensions
    (list
     ;; install runtime packages
     (service-extension
      home-profile-service-type
      hyprland-profile)

     ;; install ~/.config/hypr
     (service-extension
      home-files-service-type
      hyprland-files)))

   (default-value
    (home-hyprland-service-configuration))

   (description
    "Home service for Hyprland using a configuration package plus plugin list.")))
