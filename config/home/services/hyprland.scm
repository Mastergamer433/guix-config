(define-module (config home services hyprland)
  #:use-module (gnu packages)
  #:use-module (gnu packages linux)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (guix gexp)
  #:use-module (config packages hyprland)
  #:export (home-hyprland-service-type))

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

(define (plugins->lua plugins)
  (mixed-text-file
   "plugins.lua"
   (append-map
    (lambda (plugin)
      (list
       "hl.plugin.load(\""
       plugin
       "/lib/lib"
       (package-name plugin)
       ".so\")\n"))
    plugins)))
(define (hyprland-profile config)
  (append
   (list
    (home-hyprland-service-configuration-hyprland config)
    (home-hyprland-service-configuration-config config))
   (home-hyprland-service-configuration-plugins config)))

(define (hyprland-files config)
  `(("config/hypr/plugins.lua"
     ,(plugins->lua
       (home-hyprland-service-configuration-plugins config)))))

(define home-hyprland-service-type
  (service-type
   (name 'home-hyprland)

   (extensions
    (list
     (service-extension
      home-profile-service-type
      hyprland-profile)

     (service-extension
      home-files-service-type
      hyprland-files)))

   (default-value
     (home-hyprland-service-configuration))

   (description
    "Install Hyprland together with its configuration and plugins.")))
