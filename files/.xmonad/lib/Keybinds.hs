module Keybinds where

import XMonad
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Actions.Navigation2D
import Scratchpads
import XMonad.Util.NamedScratchpad
import qualified XMonad.StackSet as W
import qualified Data.Map as M

data KeyNode
  = Action (X ())           -- runs an Xmonad action
  | Submap KeyMap           -- points to another keymap
type KeyMap = [(String, KeyNode)]
flattenKeyMap :: KeyMap -> [(String, X ())]
flattenKeyMap km = concatMap go km
  where
    go (k, Action x) = [(k, x)]
    go (k, Submap sub) = flattenKeyMapWithPrefix k sub

-- helper to add prefix for submaps
flattenKeyMapWithPrefix :: String -> KeyMap -> [(String, X ())]
flattenKeyMapWithPrefix prefix km = concatMap f km
  where
    f (k, Action x) = [(prefix ++ " " ++ k, x)]
    f (k, Submap sub) = flattenKeyMapWithPrefix (prefix ++ " " ++ k) sub

toggleFloat w = windows $ \s ->
  if M.member w (W.floating s)
     then W.sink w s
     else W.float w (W.RationalRect 0.2 0.2 0.6 0.6) s

    -- Define app launcher commands
myLauncher :: String
myLauncher = "rofi -show run"

applicationsMap :: KeyMap
applicationsMap =
  [ ("b", Action $ spawn "firefox")
  , ("B", Action $ spawn "qutebrowser")
  , ("d", Action $ spawn "discord")
  , ("e", Action $ spawn "emacsclient -c")
  , ("g", Action $ spawn "gimp")
  , ("n", Action $ spawn "nemo")
  , ("r", Submap rofiMap)      -- nested submap
  , ("s", Submap screenshotMap) -- nested submap
  ]
rofiMap :: KeyMap
rofiMap =
  [ ("a", Action $ spawn "awiki")
  , ("r", Action $ spawn "rofi -combi-modi drun,window -show combi")
  , ("s", Action $ spawn "rofi -show ssh")
  , ("p", Action $ spawn "rofi-pass -t")
  , ("P", Action $ spawn "rofi-pass")
  , ("e", Action $ spawn "rofi-emoji")
  , ("m", Action $ spawn "rofi-mount")
  , ("u", Action $ spawn "rofi-umount")
  , ("w", Action $ spawn "wacom-setup")
  , ("y", Action $ spawn "ytplay")
  , ("Y", Action $ spawn "rofi-ytdl")
  ]

screenshotMap :: KeyMap
screenshotMap =
  [ ("d", Action $ spawn "flameshot gui -d 3000")
  , ("s", Action $ spawn "flameshot full")
  , ("S", Action $ spawn "flameshot gui")
  ]
rootMap :: KeyMap
rootMap =
  [ ("<Return>", Action $ spawn "alacritty")
  , ("e", Action $ spawn "emacs")
  , ("q", Action kill)
  , ("a", Submap applicationsMap)  -- press Mod+a to enter applications map
  ]
topMap :: KeyMap
topMap =
  [ ("M-o", Submap rootMap)
  , ("M-t", Action $ spawn "alacritty")
  , ("M-e", Action $ spawn "emacs")
  , ("M-n", Action $ windowGo D False)      -- down
  , ("M-p", Action $ windowGo U False)      -- up
  , ("M-f", Action $ windowGo R False)      -- right
  , ("M-b", Action $ windowGo L False)      -- left
  , ("M-u", withFocused toggleFloat)
  -- swap windows
  , ("M-S-n", Action $ windowSwap D False)
  , ("M-S-p", Action $ windowSwap U False)
  , ("M-S-f", Action $ windowSwap R False)
  , ("M-S-b", Action $ windowSwap L False)

    -- Launch apps
  , ("M-<Return>", Action $ spawn "alacritty")
   
  , ("M-d", Action $ spawn myLauncher)

  -- Scratchpads
  , ("M-<F1>", Action $ namedScratchpadAction myScratchpads "terminal")
  , ("M-<F2>", Action $ namedScratchpadAction myScratchpads "emacs")

  -- Kill window
  , ("M-q", Action $ kill)

  ]


myKeys :: [(String, X ())]
myKeys = flattenKeyMap topMap
