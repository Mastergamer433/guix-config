import XMonad
import XMonad.Util.EZConfig (additionalKeysP)
import qualified XMonad.StackSet as W
import XMonad.Layout.NoBorders
import XMonad.Layout.Tabbed
import XMonad.Layout.ResizableTile
import XMonad.Layout.Spacing
import XMonad.Actions.Navigation2D
import XMonad.Util.SpawnOnce
import XMonad.Hooks.ManageDocks
import XMonad.Layout.ToggleLayouts
import XMonad.Hooks.DynamicLog
import XMonad.Util.Run (spawnPipe)
import System.IO (hPutStrLn)
import XMonad.Util.NamedScratchpad
import Keybinds

-- Layouts: tiled, mirrored, tabbed, full
myLayouts = avoidStruts
          $ smartBorders
          $ spacing 6
          $ tiled
          ||| Mirror tiled
          ||| tabbed shrinkText def
          ||| Full
  where
    tiled = ResizableTall 1 (3/100) (1/2) []
-- Workspaces
myWorkspaces :: [String]
myWorkspaces = ["1:term", "2:web", "3:code", "4:mail", "5:media"]

-- Define app launcher commands
myLauncher :: String
myLauncher = "rofi -show run"

myStartupHook :: X ()
myStartupHook = do
  spawnOnce "picom &"

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

main = do
  xmproc <- spawnPipe "xmobar ~/.xmobarrc"  -- Launch Xmobar
  xmonad $ docks $ def
    { terminal           = "alacritty"
    , modMask            = mod4Mask
    , focusFollowsMouse  = False
    , borderWidth        = 2
    , normalBorderColor  = "#444444"
    , focusedBorderColor = "#ffb86c"

    , workspaces         = myWorkspaces
    , layoutHook         = myLayouts
    , manageHook         = manageDocks <+> namedScratchpadManageHook myScratchpads <+> manageHook def
    , startupHook        = myStartupHook
    , logHook            = dynamicLogWithPP xmobarPP
                             { ppOutput = hPutStrLn xmproc
                             , ppTitle  = xmobarColor "#ffb86c" "" . shorten 60
                             , ppCurrent = xmobarColor "#8be9fd" "" . wrap "[" "]"
                             , ppVisible = xmobarColor "#50fa7b" "" 
                             , ppHidden  = xmobarColor "#f1fa8c" "" 
                             , ppSep     = " | "
                                         , ppOrder   = \(ws:l:t:ex) -> [ws,l]++ex++[t]
                             }
    }
    `additionalKeysP` myKeys
