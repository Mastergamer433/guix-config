(local general (require :config.general))
(local monitors (require :config.monitors))
(local input (require :config.input))
(local decorations (require :config.decorations))
;(hl.dsp.exec_once "eww daemon")
;(hl.dsp.exec_once "eww open bar")
;(hl.dsp.exec_once "~/.config/eww/scripts/clock.sh")

(fn config []
  {
   :general general
   :decorations decoration
   :animations animations
   :input input
   :monitors monitors
  })

(hl.config (config))

(hl.workspace_rule { 
		    :workspace "w[tv1]" 
		    :gaps_out 0
		    :gaps_in 0 
		    })
(hl.workspace_rule {
		    :workspace "f[1]"
		    :gaps_out 0
		    :gaps_in 0
		    })
(hl.window_rule 
  { 
   :name "no-gaps-wtv1" 
   :match { 
           :float false 
           :workspace "w[tv1]"
   }
   :border_size 0
   :rounding 0
  })
(hl.window_rule 
  { 
   :name "no-gaps-f1" 
   :match { 
           :float false 
           :workspace "f[1]" 
   }
   :border_size 0
   :rounding 0
  })

(hl.on "hyprland.start" (fn [] (hl.dsp.exec_cmd "foot")))

(hl.bind "SUPER + Return" (hl.dsp.exec_cmd "foot"))
(hl.bind "SUPER + Q" (hl.dsp.window.close))
(hl.bind "SUPER + E" (hl.dsp.exec_cmd "emacsclient -c"))
(hl.bind "SUPER + D" (hl.dsp.exec_cmd "rofi -show run"))
(for [i 1 10]
  (local key (% i 10))
  (hl.bind (.. "SUPER + " key) (hl.dsp.focus { :workspace i }))
  (hl.bind (.. "SUPER + SHIFT + " key) (hl.dsp.window.move { :workspace i })))
