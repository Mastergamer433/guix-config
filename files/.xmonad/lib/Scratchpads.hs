module Scratchpads where
import XMonad.Util.NamedScratchpad
import qualified XMonad.StackSet as W
import XMonad.StackSet (RationalRect)
import XMonad.Hooks.ManageHelpers (isDialog)
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers (doCenterFloat)
import XMonad.Hooks.ManageHelpers (doRectFloat)
import XMonad.Util.NamedScratchpad
import XMonad.Layout
import XMonad

-- Scratchpads
myScratchpads :: [NamedScratchpad]
myScratchpads =
  [ NS "terminal" "alacritty -title scratchpad" (title =? "scratchpad")
      (customFloating $ W.RationalRect l t w h)
  , NS "emacs" "emacs --name scratchpad" (title =? "scratchpad")
      (customFloating $ W.RationalRect l t w h)
  ]
  where
    h = 0.5    -- height
    w = 0.6    -- width
    t = 0.25   -- top offset
    l = 0.2    -- left offset
