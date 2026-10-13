;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2026
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.

(define-module (config home services niri-new)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu home services)
  #:use-module (gnu packages window-management)
  #:use-module (gnu services configuration)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:export (;; Configuration records.
            niri-configuration
            niri-configuration-package
            niri-configuration-outputs
            niri-configuration-input
            niri-configuration-layout
            niri-configuration-keybindings
            niri-configuration-startup-programs
            niri-configuration-startup-shell-commands
            niri-configuration-window-rules
            niri-configuration-layer-rules
            niri-configuration-includes
            niri-configuration-extra-content
            niri-output
            niri-output-identifier
            niri-output-mode
            niri-output-scale
            niri-output-transform
            niri-output-position
            niri-output-variable-refresh-rate
            niri-output-focus-at-startup
            niri-output-backdrop-color
            niri-output-hot-corners
            niri-input
            niri-input-keyboard-layout
            niri-input-keyboard-variant
            niri-input-keyboard-options
            niri-input-keyboard-model
            niri-input-touchpad
            niri-layout
            niri-layout-gaps
            niri-layout-center-focused-column
            niri-layout-always-center-single-column
            niri-layout-empty-workspace-above-first
            niri-layout-default-column-display
            niri-layout-background-color
            niri-layout-focus-ring
	    niri-layout-border
            niri-focus-ring
            niri-focus-ring-width
            niri-focus-ring-active-color
            niri-focus-ring-inactive-color
            niri-focus-ring-urgent-color
            niri-bind
            niri-bind-key
            niri-bind-action
            niri-bind-options
            niri-window-rule
            niri-window-rule-match
	    niri-window-height
            niri-layer-rule
            niri-layer-rule-match
            niri-layer-rule-properties
	    niri-column-width
niri-floating-position
niri-gradient
niri-border
niri-offset
niri-shadow
niri-tab-indicator
niri-background-effect
niri-popups
            niri-spawn
            niri-spawn-sh
            niri-action
            niri-configuration->file
            home-niri-service-type
            %empty-niri-configuration))

;; --------------------------------------------------------------------------
;; Helpers.

(define (string-ish? x)
  (or (string? x) (gexp? x) (file-like? x)))

(define (string-or-symbol? x)
  (or (string? x) (symbol? x)))

(define (list-of-string-ish? x)
  (and (list? x) (every string-ish? x)))

(define (list-of-symbols? x)
  (and (list? x) (every symbol? x)))

(define (niri-action? x)
  (and (pair? x) (memq (car x) '(action spawn spawn-sh))))

(define (kdl-boolean-option name value)
  (and value name))

(define (alist? x)
  (and (list? x)
       (every pair? x)))

(define (quote-kdl-string s)
  (let ((s (cond ((string? s) s)
                 ((symbol? s) (symbol->string s))
                 (else (format #f "~a" s)))))
    (string-append
     "\""
     (string-map (lambda (c)
                   (case c
                     ((#\") "\\\"")
                     ((#\\) "\\\\")
                     ((#\newline) "\\n")
                     ((#\return) "\\r")
                     ((#\tab) "\\t")
                     (else c)))
                 s)
     "\"")))

(define (serialize-value value)
  (cond
   ((string? value) (quote-kdl-string value))
   ((symbol? value) (symbol->string value))
   ((boolean? value) (if value "true" "false"))
   ((number? value) (number->string value))
   ((gexp? value) value)
   ((file-like? value) value)
   (else (format #f "~a" value))))

(define (kdl-property name value)
  (and (not (eq? value %unset-value))
       (string-append name " " (serialize-value value))))

(define (kdl-flag name value)
  (cond ((eq? value #t) name)
        ((eq? value #f) (string-append name " false"))
        (else #f)))

(define (kdl-block name body)
  (let ((body
         (append-map
          (lambda (line)
            (if (list? line)
                line
                (list line)))
          (filter identity body))))
    (if (null? body)
        '()
        (append
         (list (string-append name " {"))
         (map (lambda (line)
                (string-append "    " line))
              body)
         (list "}")))))

(define (serialize-action action)
  (cond
   ;; (niri-spawn PROGRAM ARG ...)
   ((and (pair? action) (eq? (car action) 'spawn))
    (string-append "spawn"
                   (apply string-append
                          (map (lambda (x)
                                 (string-append " " (serialize-value x)))
                               (cdr action)))))
   ;; (niri-spawn-sh COMMAND)
   ((and (pair? action) (eq? (car action) 'spawn-sh))
    (string-append "spawn-sh " (serialize-value (cadr action))))
   ;; (niri-action 'close-window) or (niri-action 'move-column-left 1)
   ((and (pair? action) (eq? (car action) 'action))
    (string-append (symbol->string (cadr action))
                   (apply string-append
                          (map (lambda (x)
                                 (string-append " " (serialize-value x)))
                               (cddr action)))))
   ;; Raw action string, useful for actions added by newer Niri releases.
   ((string? action) action)
   (else (error "unknown Niri action" action))))

(define (niri-spawn program . args)
  (cons 'spawn (cons program args)))

(define (niri-spawn-sh command)
  (list 'spawn-sh command))

(define (niri-action action . args)
  (cons 'action (cons action args)))

;; --------------------------------------------------------------------------
;; Records.

(define-maybe string (no-serialization))
(define-maybe boolean (no-serialization))
(define-maybe number (no-serialization))

(define-configuration/no-serialization niri-output
  (identifier
   (string "*")
   "Output name.")
  (mode
   maybe-string
   "Output mode, e.g. 1920x1080@120.")
  (scale
   maybe-number
   "Output scale.")
  (transform
   maybe-string
   "Output transform, e.g. 90.")
  (position
   maybe-string
   "Output position as a raw KDL value, e.g. x=0 y=0.")
  (variable-refresh-rate
   maybe-boolean
   "Enable or disable variable refresh rate.")
  (focus-at-startup
   maybe-boolean
   "Focus this output at startup.")
  (backdrop-color
   maybe-string
   "Output backdrop color.")
  (hot-corners
   (list-of-symbols '())
   "Hot corners: top-left, top-right, bottom-left, bottom-right, or off."))
(define-maybe niri-output (no-serialization))

(define (niri-outputs? x)
  (every niri-output? x))

(define-configuration/no-serialization niri-input
  (keyboard-layout
   maybe-string
   "XKB keyboard layout.")
  (keyboard-variant
   maybe-string
   "XKB keyboard variant.")
  (keyboard-options
   maybe-string
   "XKB keyboard options.")
  (keyboard-model
   maybe-string
   "XKB keyboard model.")
  (touchpad
   (list-of-string-ish '())
   "Raw KDL properties for the touchpad section."))
(define-maybe niri-input (no-serialization))

(define-configuration/no-serialization niri-gradient
  (from
   maybe-string
   "Gradient starting color.")
  (to
   maybe-string
   "Gradient ending color.")
  (angle
   maybe-number
   "Gradient angle.")
  (relative-to
   maybe-string
   "Gradient coordinate space."))

(define-maybe niri-gradient (no-serialization))

(define-configuration/no-serialization niri-border
  (off
   maybe-boolean
   "Disable the border.")
  (on
   maybe-boolean
   "Enable the border.")
  (width
   maybe-number
   "Width of the border.")
  (active-color
   maybe-string
   "Active border color.")
  (inactive-color
   maybe-string
   "Inactive border color.")
  (urgent-color
   maybe-string
   "Urgent border color.")
  (active-gradient
   maybe-niri-gradient
   "Active border gradient.")
  (inactive-gradient
   maybe-niri-gradient
   "Inactive border gradient.")
  (urgent-gradient
   maybe-niri-gradient
   "Urgent border gradient."))

(define-maybe niri-border (no-serialization))

(define-configuration/no-serialization niri-focus-ring
  (off
   maybe-boolean
   "Disable the focus ring.")
  (on
   maybe-boolean
   "Enable the focus ring.")
  (width
   maybe-number
   "Width of the focus ring.")
  (active-color
   maybe-string
   "Active focus-ring color.")
  (inactive-color
   maybe-string
   "Inactive focus-ring color.")
  (urgent-color
   maybe-string
   "Urgent focus-ring color.")
  (active-gradient
   maybe-niri-gradient
   "Active focus-ring gradient.")
  (inactive-gradient
   maybe-niri-gradient
   "Inactive focus-ring gradient.")
  (urgent-gradient
   maybe-niri-gradient
   "Urgent focus-ring gradient."))

(define-maybe niri-focus-ring (no-serialization))

(define-configuration/no-serialization niri-layout
  (gaps
   maybe-number
   "Gap between windows in logical pixels.")
  (center-focused-column
   maybe-string
   "Center-focused-column mode.")
  (always-center-single-column
   maybe-boolean
   "Always center a single column.")
  (empty-workspace-above-first
   maybe-boolean
   "Keep an empty workspace above the first workspace.")
  (default-column-display
   maybe-string
   "Default column display, e.g. normal or tabbed.")
  (background-color
   maybe-string
   "Layout background color.")
  (focus-ring
   maybe-niri-focus-ring
   "Focus-ring settings.")
  (border
   maybe-niri-border
   "Border settings."))

(define-maybe niri-layout (no-serialization))

(define-configuration/no-serialization niri-bind
  (key
   string
   "Niri key combination.")
  (action
   niri-action
   "Niri action created by niri-action, niri-spawn, or niri-spawn-sh.")
  (options
   (list-of-string-ish '())
   "Raw KDL bind properties, e.g. allow-when-locked=true."))
(define-maybe niri-bind (no-serialization))

(define (niri-binds? x)
  (every niri-bind? x))


(define-configuration/no-serialization niri-offset
  (x
   maybe-number
   "Horizontal offset.")
  (y
   maybe-number
   "Vertical offset."))

(define-maybe niri-offset (no-serialization))

(define-configuration/no-serialization niri-column-width
  (proportion
   maybe-number
   "Column width as a proportion.")
  (fixed
   maybe-number
   "Fixed column width in pixels."))

(define-maybe niri-column-width (no-serialization))

(define-configuration/no-serialization niri-window-height
  (proportion
   maybe-number
   "Window height as a proportion.")
  (fixed
   maybe-number
   "Fixed window height in pixels."))

(define-maybe niri-window-height (no-serialization))

(define-configuration/no-serialization niri-floating-position
  (x
   maybe-number
   "Horizontal position.")
  (y
   maybe-number
   "Vertical position.")
  (relative-to
   maybe-string
   "Position reference."))

(define-maybe niri-floating-position (no-serialization))

(define-configuration/no-serialization niri-shadow
  (on
   maybe-boolean
   "Enable the shadow.")
  (off
   maybe-boolean
   "Disable the shadow.")
  (softness
   maybe-number
   "Shadow softness.")
  (spread
   maybe-number
   "Shadow spread.")
  (offset
   maybe-niri-offset
   "Shadow offset.")
  (draw-behind-window
   maybe-boolean
   "Draw the shadow behind the window.")
  (color
   maybe-string
   "Shadow color.")
  (inactive-color
   maybe-string
   "Inactive shadow color."))

(define-maybe niri-shadow (no-serialization))

(define-configuration/no-serialization niri-tab-indicator
  (active-color
   maybe-string
   "Active tab-indicator color.")
  (inactive-color
   maybe-string
   "Inactive tab-indicator color.")
  (urgent-color
   maybe-string
   "Urgent tab-indicator color.")
  (active-gradient
   maybe-niri-gradient
   "Active tab-indicator gradient.")
  (inactive-gradient
   maybe-niri-gradient
   "Inactive tab-indicator gradient.")
  (urgent-gradient
   maybe-niri-gradient
   "Urgent tab-indicator gradient."))

(define-maybe niri-tab-indicator (no-serialization))

(define-configuration/no-serialization niri-background-effect
  (xray
   maybe-boolean
   "Enable xray.")
  (blur
   maybe-boolean
   "Enable blur.")
  (noise
   maybe-number
   "Noise amount.")
  (saturation
   maybe-number
   "Color saturation."))

(define-maybe niri-background-effect (no-serialization))

(define-configuration/no-serialization niri-popups
  (opacity
   maybe-number
   "Popup opacity.")
  (geometry-corner-radius
   maybe-number
   "Popup geometry corner radius.")
  (background-effect
   maybe-niri-background-effect
   "Popup background effect."))

(define-maybe niri-popups (no-serialization))

(define-configuration/no-serialization niri-window-rule
  ;; Match criteria.
  (match
   (alist '())
   "Window matching criteria as key/value pairs.")

  ;; Properties applied once upon opening.
  (default-column-width
   maybe-niri-column-width
   "Default column width.")

  (default-window-height
   maybe-niri-window-height
   "Default window height.")

  (open-on-output
   maybe-string
   "Output on which to open the window.")

  (open-on-workspace
   maybe-string
   "Workspace on which to open the window.")

  (open-maximized
   maybe-boolean
   "Open maximized.")

  (open-maximized-to-edges
   maybe-boolean
   "Open maximized to the edges.")

  (open-fullscreen
   maybe-boolean
   "Open fullscreen.")

  (open-floating
   maybe-boolean
   "Open floating.")

  (open-focused
   maybe-boolean
   "Open focused.")

  ;; Properties applied continuously.
  (draw-border-with-background
   maybe-boolean
   "Draw the border with the background.")

  (opacity
   maybe-number
   "Window opacity.")

  (block-out-from
   maybe-string
   "Block the window out from a capture target.")

  (variable-refresh-rate
   maybe-boolean
   "Enable variable refresh rate.")

  (default-column-display
   maybe-string
   "Default column display.")

  (default-floating-position
   maybe-niri-floating-position
   "Default floating position.")

  (scroll-factor
   maybe-number
   "Scroll factor.")

  (pinch-sensitivity
   maybe-number
   "Pinch sensitivity.")

  (on-xdg-activate
   maybe-string
   "XDG activation behavior.")

  (focus-ring
   maybe-niri-focus-ring
   "Focus-ring configuration.")

  (border
   maybe-niri-border
   "Border configuration.")

  (shadow
   maybe-niri-shadow
   "Shadow configuration.")

  (tab-indicator
   maybe-niri-tab-indicator
   "Tab-indicator configuration.")

  (geometry-corner-radius
   maybe-number
   "Geometry corner radius.")

  (clip-to-geometry
   maybe-boolean
   "Clip to geometry.")

  (tiled-state
   maybe-boolean
   "Whether the window is tiled.")

  (baba-is-float
   maybe-boolean
   "Enable baba-is-float.")

  (background-effect
   maybe-niri-background-effect
   "Background effect.")

  (popups
   maybe-niri-popups
   "Popup configuration.")

  (min-width
   maybe-number
   "Minimum width.")

  (max-width
   maybe-number
   "Maximum width.")

  (min-height
   maybe-number
   "Minimum height.")

  (max-height
   maybe-number
   "Maximum height."))

(define-maybe niri-window-rule (no-serialization))

(define (niri-window-rules? x)
  (every niri-window-rule? x))

(define-configuration/no-serialization niri-layer-rule
  (match
   (list-of-string-ish '())
   "Raw match expressions, e.g. namespace=\"^notifications$\".")
  (properties
   (list-of-string-ish '())
   "Raw KDL properties/blocks inside the rule."))
(define-maybe niri-layer-rule (no-serialization))

(define (niri-layer-rules? x)
  (every niri-layer-rule? x))

;; --------------------------------------------------------------------------
;; Top-level configuration.

(define %niri-default-package
  niri)

(define-configuration/no-serialization niri-configuration
  (prefer-no-csd
   (boolean #f)
   "Whether to prefer client-side decoration avoidance.")
  (package
   (package %niri-default-package)
   "Niri package to add to the Home profile.")
  (outputs
   (niri-outputs '())
   "Output configurations.")
  (input
   maybe-niri-input
   "Keyboard/input configuration.")
  (layout
   maybe-niri-layout
   "Layout configuration.")
  (keybindings
   (niri-binds '())
   "Key bindings.")
  (startup-programs
   (list '())
   "Programs and arguments to run at startup. Each element is a list.")
  (startup-shell-commands
   (list-of-string-ish '())
   "Shell commands to run at startup.")
  (window-rules
   (niri-window-rules '())
   "Window rules.")
  (layer-rules
   (niri-layer-rules '())
   "Layer rules.")
  (includes
   (list-of-string-ish '())
   "KDL files to include, in order.")
  (extra-content
   (list-of-string-ish '())
   "Raw KDL lines appended at the end of the generated configuration."))

;; --------------------------------------------------------------------------
;; Serialization.

(define (serialize-boolean-option name value)
  (if value
      (list name)
      '()))

(define (serialize-output output)
  (let ((id (niri-output-identifier output))
        (mode (niri-output-mode output))
        (scale (niri-output-scale output))
        (transform (niri-output-transform output))
        (position (niri-output-position output))
        (vrr (niri-output-variable-refresh-rate output))
        (focus (niri-output-focus-at-startup output))
        (backdrop (niri-output-backdrop-color output))
        (corners (niri-output-hot-corners output)))
    (kdl-block
     (string-append "output " (quote-kdl-string id))
     (list
      (and mode (kdl-property "mode" mode))
      (and scale (kdl-property "scale" scale))
      (and transform (kdl-property "transform" transform))
      position
      (kdl-flag "variable-refresh-rate" vrr)
      (kdl-flag "focus-at-startup" focus)
      (and backdrop (kdl-property "backdrop-color" backdrop))
      (and (pair? corners)
           (kdl-block "hot-corners"
                      (map (lambda (corner)
                             (symbol->string corner))
                           corners)))))))

(define (serialize-input input)
  (let ((body
         (filter identity
                 (list
                  (kdl-block
                   "keyboard"
                   (list
                    (kdl-block
                     "xkb"
                     (filter identity
                             (list
                              (and (niri-input-keyboard-layout input)
                                   (kdl-property
                                    "layout"
                                    (niri-input-keyboard-layout input)))
                              (and (niri-input-keyboard-variant input)
                                   (kdl-property
                                    "variant"
                                    (niri-input-keyboard-variant input)))
                              (and (niri-input-keyboard-options input)
                                   (kdl-property
                                    "options"
                                    (niri-input-keyboard-options input)))
                              (and (niri-input-keyboard-model input)
                                   (kdl-property
                                    "model"
                                    (niri-input-keyboard-model input))))))))
                  (and (pair? (niri-input-touchpad input))
                       (kdl-block
                        "touchpad"
                        (niri-input-touchpad input)))))))
    (kdl-block "input" body)))

(define (serialize-focus-ring ring)
  (kdl-block
   "focus-ring"
   (serialize-focus-ring-body ring)))


(define (serialize-layout layout)
  (kdl-block
   "layout"
   (list
    (and (niri-layout-gaps layout)
         (kdl-property "gaps" (niri-layout-gaps layout)))
    (and (niri-layout-center-focused-column layout)
         (kdl-property "center-focused-column"
                       (niri-layout-center-focused-column layout)))
    (kdl-flag "always-center-single-column"
              (niri-layout-always-center-single-column layout))
    (kdl-flag "empty-workspace-above-first"
              (niri-layout-empty-workspace-above-first layout))
    (and (niri-layout-default-column-display layout)
         (kdl-property "default-column-display"
                       (niri-layout-default-column-display layout)))
    (and (niri-layout-background-color layout)
         (kdl-property "background-color"
                       (niri-layout-background-color layout)))
    (let ((ring (niri-layout-focus-ring layout)))
      (and (not (eq? ring %unset-value))
           (serialize-focus-ring ring)))
    (let ((border (niri-layout-border layout)))
      (and (not (eq? border %unset-value))
           (serialize-border border))))))

(define (serialize-bind bind)
  (let ((key (niri-bind-key bind))
        (options (niri-bind-options bind))
        (action (serialize-action (niri-bind-action bind))))
    (string-append
     key
     (if (null? options)
         ""
         (string-append " " (string-join options " ")))
     " { " action "; }")))

(define (kdl-boolean-property name value)
  (and (not (eq? value %unset-value))
       (kdl-property name value)))

(define (serialize-kdl-arguments arguments)
  (string-join
   (filter identity
           (map (lambda (argument)
                  (and argument
                       (string-append
                        (car argument)
                        "="
                        (serialize-value (cdr argument)))))
                arguments))
   " "))

(define (serialize-gradient-property name gradient)
  (and (not (eq? gradient %unset-value))
       (let ((args
              (serialize-kdl-arguments
               `(("from" . ,(niri-gradient-from gradient))
                 ("to" . ,(niri-gradient-to gradient))
                 ("angle" . ,(niri-gradient-angle gradient))
                 ("relative-to" . ,(niri-gradient-relative-to gradient))))))
         (string-append name
                        (if (string-null? args)
                            ""
                            (string-append " " args))))))

(define (serialize-column-width width)
  (kdl-block
   "default-column-width"
   (list
    (and (niri-column-width-proportion width)
         (kdl-property
          "proportion"
          (niri-column-width-proportion width)))
    (and (niri-column-width-fixed width)
         (kdl-property
          "fixed"
          (niri-column-width-fixed width))))))

(define (serialize-window-height height)
  (kdl-block
   "default-window-height"
   (list
    (and (niri-window-height-proportion height)
         (kdl-property
          "proportion"
          (niri-window-height-proportion height)))
    (and (niri-window-height-fixed height)
         (kdl-property
          "fixed"
          (niri-window-height-fixed height))))))

(define (serialize-niri-floating-position position)
  (let ((args
         (serialize-kdl-arguments
          `(("x" ,(niri-floating-position-x position))
            ("y" ,(niri-floating-position-y position))
            ("relative-to" ,(niri-floating-position-relative-to position))))))
    (string-append "default-floating-position " args)))

(define (serialize-focus-ring-body ring)
  (list
   (kdl-flag "off" (niri-focus-ring-off ring))
   (kdl-flag "on" (niri-focus-ring-on ring))

   (and (niri-focus-ring-width ring)
        (kdl-property
         "width"
         (niri-focus-ring-width ring)))

   (and (niri-focus-ring-active-color ring)
        (kdl-property
         "active-color"
         (niri-focus-ring-active-color ring)))

   (and (niri-focus-ring-inactive-color ring)
        (kdl-property
         "inactive-color"
         (niri-focus-ring-inactive-color ring)))

   (and (niri-focus-ring-urgent-color ring)
        (kdl-property
         "urgent-color"
         (niri-focus-ring-urgent-color ring)))

   (and (niri-focus-ring-active-gradient ring)
        (serialize-gradient-property
         "active-gradient"
         (niri-focus-ring-active-gradient ring)))

   (and (niri-focus-ring-inactive-gradient ring)
        (serialize-gradient-property
         "inactive-gradient"
         (niri-focus-ring-inactive-gradient ring)))

   (and (niri-focus-ring-urgent-gradient ring)
        (serialize-gradient-property
         "urgent-gradient"
         (niri-focus-ring-urgent-gradient ring)))))

(define (serialize-window-focus-ring ring)
  (kdl-block
   "focus-ring"
   (serialize-focus-ring-body ring)))

(define (serialize-border border)
  (kdl-block
   "border"
   (list
    (kdl-flag "off" (niri-border-off border))
(kdl-flag "on" (niri-border-on border))

    (and (niri-border-width border)
         (kdl-property
          "width"
          (niri-border-width border)))

    (and (niri-border-active-color border)
         (kdl-property
          "active-color"
          (niri-border-active-color border)))

    (and (niri-border-inactive-color border)
         (kdl-property
          "inactive-color"
          (niri-border-inactive-color border)))

    (and (niri-border-urgent-color border)
         (kdl-property
          "urgent-color"
          (niri-border-urgent-color border)))

    (and (niri-border-active-gradient border)
         (serialize-gradient-property
          "active-gradient"
          (niri-border-active-gradient border)))

    (and (niri-border-inactive-gradient border)
         (serialize-gradient-property
          "inactive-gradient"
          (niri-border-inactive-gradient border)))

    (and (niri-border-urgent-gradient border)
         (serialize-gradient-property
          "urgent-gradient"
          (niri-border-urgent-gradient border))))))

(define (serialize-offset offset)
  (serialize-kdl-arguments
   `(("x" . ,(niri-offset-x offset))
     ("y" . ,(niri-offset-y offset)))))

(define (serialize-shadow shadow)
  (kdl-block
   "shadow"
   (list
    (kdl-flag "off" (niri-shadow-off shadow))
(kdl-flag "on" (niri-shadow-on shadow))

    (and (niri-shadow-softness shadow)
         (kdl-property
          "softness"
          (niri-shadow-softness shadow)))

    (and (niri-shadow-spread shadow)
         (kdl-property
          "spread"
          (niri-shadow-spread shadow)))

    (and (niri-shadow-offset shadow)
         (string-append
          "offset "
          (serialize-offset
           (niri-shadow-offset shadow))))

    (kdl-flag
     "draw-behind-window"
     (niri-shadow-draw-behind-window shadow))

    (and (niri-shadow-color shadow)
         (kdl-property
          "color"
          (niri-shadow-color shadow)))

    (and (niri-shadow-inactive-color shadow)
         (kdl-property
          "inactive-color"
          (niri-shadow-inactive-color shadow))))))

(define (serialize-tab-indicator indicator)
  (kdl-block
   "tab-indicator"
   (list
    (and (niri-tab-indicator-active-color indicator)
         (kdl-property
          "active-color"
          (niri-tab-indicator-active-color indicator)))

    (and (niri-tab-indicator-inactive-color indicator)
         (kdl-property
          "inactive-color"
          (niri-tab-indicator-inactive-color indicator)))

    (and (niri-tab-indicator-urgent-color indicator)
         (kdl-property
          "urgent-color"
          (niri-tab-indicator-urgent-color indicator)))

    (and (niri-tab-indicator-active-gradient indicator)
         (serialize-gradient-property
          "active-gradient"
          (niri-tab-indicator-active-gradient indicator)))

    (and (niri-tab-indicator-inactive-gradient indicator)
         (serialize-gradient-property
          "inactive-gradient"
          (niri-tab-indicator-inactive-gradient indicator)))

    (and (niri-tab-indicator-urgent-gradient indicator)
         (serialize-gradient-property
          "urgent-gradient"
          (niri-tab-indicator-urgent-gradient indicator))))))

(define (serialize-background-effect effect)
  (kdl-block
   "background-effect"
   (list
    (kdl-flag "xray" (niri-background-effect-xray effect))
    (kdl-flag "blur" (niri-background-effect-blur effect))

    (and (niri-background-effect-noise effect)
         (kdl-property
          "noise"
          (niri-background-effect-noise effect)))

    (and (niri-background-effect-saturation effect)
         (kdl-property
          "saturation"
          (niri-background-effect-saturation effect))))))

(define (serialize-popups popups)
  (kdl-block
   "popups"
   (list
    (and (niri-popups-opacity popups)
         (kdl-property
          "opacity"
          (niri-popups-opacity popups)))

    (and (niri-popups-geometry-corner-radius popups)
         (kdl-property
          "geometry-corner-radius"
          (niri-popups-geometry-corner-radius popups)))

    (let ((effect (niri-popups-background-effect popups)))
      (and (not (eq? effect %unset-value))
           (serialize-background-effect effect))))))

(define (serialize-window-rule-match match)
  (string-append
   "match "
   (if (symbol? (car match))
       (symbol->string (car match))
       (car match))
   "="
   (serialize-value (cdr match))))

(define (serialize-window-rule rule)
  (kdl-block
   "window-rule"
   (append

    ;; Match criteria.
    (map serialize-window-rule-match
         (niri-window-rule-match rule))

    ;; Properties applied once upon opening.
    (let ((width (niri-window-rule-default-column-width rule)))
      (if (eq? width %unset-value)
          '()
          (list (serialize-column-width width))))

    (let ((height (niri-window-rule-default-window-height rule)))
      (if (eq? height %unset-value)
          '()
          (list (serialize-window-height height))))

    (list
     (and (niri-window-rule-open-on-output rule)
          (kdl-property
           "open-on-output"
           (niri-window-rule-open-on-output rule)))

     (and (niri-window-rule-open-on-workspace rule)
          (kdl-property
           "open-on-workspace"
           (niri-window-rule-open-on-workspace rule)))

     (kdl-boolean-property
      "open-maximized"
      (niri-window-rule-open-maximized rule))

     (kdl-boolean-property
      "open-maximized-to-edges"
      (niri-window-rule-open-maximized-to-edges rule))

     (kdl-boolean-property
      "open-fullscreen"
      (niri-window-rule-open-fullscreen rule))

     (kdl-boolean-property
      "open-floating"
      (niri-window-rule-open-floating rule))

     (kdl-boolean-property
      "open-focused"
      (niri-window-rule-open-focused rule))

     ;; Continuous properties.
     (kdl-boolean-property
      "draw-border-with-background"
      (niri-window-rule-draw-border-with-background rule))

     (and (niri-window-rule-opacity rule)
          (kdl-property
           "opacity"
           (niri-window-rule-opacity rule)))

     (and (niri-window-rule-block-out-from rule)
          (kdl-property
           "block-out-from"
           (niri-window-rule-block-out-from rule)))

     (kdl-boolean-property
      "variable-refresh-rate"
      (niri-window-rule-variable-refresh-rate rule))

     (and (niri-window-rule-default-column-display rule)
          (kdl-property
           "default-column-display"
           (niri-window-rule-default-column-display rule)))

     (let ((position
            (niri-window-rule-default-floating-position rule)))
       (and (not (eq? position %unset-value))
            (serialize-floating-position position)))

     (and (niri-window-rule-scroll-factor rule)
          (kdl-property
           "scroll-factor"
           (niri-window-rule-scroll-factor rule)))

     (and (niri-window-rule-pinch-sensitivity rule)
          (kdl-property
           "pinch-sensitivity"
           (niri-window-rule-pinch-sensitivity rule)))

     (and (niri-window-rule-on-xdg-activate rule)
          (kdl-property
           "on-xdg-activate"
           (niri-window-rule-on-xdg-activate rule))))

    ;; Nested visual configuration.
    (let ((ring (niri-window-rule-focus-ring rule)))
      (if (eq? ring %unset-value)
          '()
          (list (serialize-window-focus-ring ring))))

    (let ((border (niri-window-rule-border rule)))
      (if (eq? border %unset-value)
          '()
          (list (serialize-border border))))

    (let ((shadow (niri-window-rule-shadow rule)))
      (if (eq? shadow %unset-value)
          '()
          (list (serialize-shadow shadow))))

    (let ((indicator (niri-window-rule-tab-indicator rule)))
      (if (eq? indicator %unset-value)
          '()
          (list (serialize-tab-indicator indicator))))

    (list
     (and (niri-window-rule-geometry-corner-radius rule)
          (kdl-property
           "geometry-corner-radius"
           (niri-window-rule-geometry-corner-radius rule)))

     (kdl-boolean-property
      "clip-to-geometry"
      (niri-window-rule-clip-to-geometry rule))

     (kdl-boolean-property
      "tiled-state"
      (niri-window-rule-tiled-state rule))

     (kdl-boolean-property
      "baba-is-float"
      (niri-window-rule-baba-is-float rule)))

    (let ((effect (niri-window-rule-background-effect rule)))
      (if (eq? effect %unset-value)
          '()
          (list (serialize-background-effect effect))))

    (let ((popups (niri-window-rule-popups rule)))
      (if (eq? popups %unset-value)
          '()
          (list (serialize-popups popups))))

    ;; Size constraints.
    (list
     (and (niri-window-rule-min-width rule)
          (kdl-property
           "min-width"
           (niri-window-rule-min-width rule)))

     (and (niri-window-rule-max-width rule)
          (kdl-property
           "max-width"
           (niri-window-rule-max-width rule)))

     (and (niri-window-rule-min-height rule)
          (kdl-property
           "min-height"
           (niri-window-rule-min-height rule)))

     (and (niri-window-rule-max-height rule)
          (kdl-property
           "max-height"
           (niri-window-rule-max-height rule)))))))

(define (serialize-layer-rule rule)
  (kdl-block
   "layer-rule"
   (append
    (map (lambda (x) (string-append "match " x))
         (niri-layer-rule-match rule))
    (niri-layer-rule-properties rule))))

(define (serialize-startup-program command)
  (string-append
   "spawn-at-startup"
   (apply string-append
          (map (lambda (x)
                 (string-append " " (serialize-value x)))
               command))))

(define (serialize-startup-shell command)
  (string-append "spawn-sh-at-startup " (quote-kdl-string command)))

(define (with-heading title lines)
  (if (null? lines)
      '()
      (append (list "" (string-append "// " title)) lines)))


(define (niri-configuration->file conf)
  "Return a computed file containing the KDL configuration for CONF."
  (let ((lines
         (append
          (list "// Auto-generated configuration."
                "// DO NOT EDIT MANUALLY.")
          (serialize-boolean-option
           "prefer-no-csd"
           (niri-configuration-prefer-no-csd conf))
          (with-heading
           "Outputs"
           (append-map serialize-output
                       (niri-configuration-outputs conf)))
          (let ((input (niri-configuration-input conf)))
            (if (eq? input %unset-value)
                '()
                (with-heading "Input" (serialize-input input))))
          (let ((layout (niri-configuration-layout conf)))
            (if (eq? layout %unset-value)
                '()
                (with-heading "Layout" (serialize-layout layout))))
          (with-heading
           "Keybindings"
           (if (null? (niri-configuration-keybindings conf))
               '()
               (kdl-block
                "binds"
                (map serialize-bind
                     (niri-configuration-keybindings conf)))))
          (with-heading
           "Startup programs"
           (append
            (map serialize-startup-program
                 (niri-configuration-startup-programs conf))
            (map serialize-startup-shell
                 (niri-configuration-startup-shell-commands conf))))
          (with-heading
           "Window rules"
           (append-map serialize-window-rule
                       (niri-configuration-window-rules conf)))
          (with-heading
           "Layer rules"
           (append-map serialize-layer-rule
                       (niri-configuration-layer-rules conf)))
          (with-heading
           "Includes"
           (map (lambda (file)
                  (string-append "include " (serialize-value file)))
                (niri-configuration-includes conf)))
          (with-heading
           "Extra content"
           (niri-configuration-extra-content conf)))))
    (computed-file
     "niri-config.kdl"
     #~(begin
         (use-modules (ice-9 format))
         (call-with-output-file #$output
           (lambda (port)
             (for-each
              (lambda (line)
                (format port "~a~%" line))
              '#$lines)))))))


;; --------------------------------------------------------------------------
;; Service composition.

(define %empty-niri-configuration
  (niri-configuration
   (outputs '())
   (keybindings '())
   (startup-programs '())
   (startup-shell-commands '())
   (window-rules '())
   (layer-rules '())
   (includes '())
   (extra-content '())))

(define (niri-configuration->files conf)
  `((".config/niri/config.kdl" ,(niri-configuration->file conf))))

(define (niri-combine config1 config2)
  (niri-configuration
   (package (niri-configuration-package config2))
   (prefer-no-csd
 (or (niri-configuration-prefer-no-csd config1)
     (niri-configuration-prefer-no-csd config2)))
   (outputs
    (append (niri-configuration-outputs config1)
            (niri-configuration-outputs config2)))
   (input
    (let ((a (niri-configuration-input config1))
          (b (niri-configuration-input config2)))
      (if (eq? a %unset-value) b
          (if (eq? b %unset-value) a
              (throw "[Niri configuration] Too many input configurations have been found.")))))
   (layout
    (let ((a (niri-configuration-layout config1))
          (b (niri-configuration-layout config2)))
      (if (eq? a %unset-value) b
          (if (eq? b %unset-value) a
              (throw "[Niri configuration] Too many layout configurations have been found.")))))
   (keybindings
    (append (niri-configuration-keybindings config1)
            (niri-configuration-keybindings config2)))
   (startup-programs
    (append (niri-configuration-startup-programs config1)
            (niri-configuration-startup-programs config2)))
   (startup-shell-commands
    (append (niri-configuration-startup-shell-commands config1)
            (niri-configuration-startup-shell-commands config2)))
   (window-rules
    (append (niri-configuration-window-rules config1)
            (niri-configuration-window-rules config2)))
   (layer-rules
    (append (niri-configuration-layer-rules config1)
            (niri-configuration-layer-rules config2)))
   (includes
    (append (niri-configuration-includes config1)
            (niri-configuration-includes config2)))
   (extra-content
    (append (niri-configuration-extra-content config1)
            (niri-configuration-extra-content config2)))))

(define (niri-compose lst)
  (match lst
    (() %unset-value)
    ((h) h)
    ((h . t) (fold niri-combine h t))))

(define (niri-extend ini res)
  (if (eq? res %unset-value)
      ini
      (niri-combine ini res)))

(define home-niri-service-type
  (service-type
   (name 'home-niri-config)
   (extensions
    (list
     (service-extension home-files-service-type
                        niri-configuration->files)
     (service-extension
      home-profile-service-type
      (lambda (conf)
        (list (niri-configuration-package conf))))))
   (compose niri-compose)
   (extend niri-extend)
   (description
    "Configure Niri by providing a file @file{~/.config/niri/config.kdl}.")
   (default-value (niri-configuration))))
