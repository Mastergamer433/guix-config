{{ define "direction" -}}
{{- if eq . "H" -}}left
{{- else if eq . "J" -}}down
{{- else if eq . "K" -}}up
{{- else if eq . "L" -}}right
{{- else if eq . "U" -}}down
{{- else if eq . "I" -}}up
{{- end -}}
{{- end }}

{{ define "niri" }}

prefer-no-csd

window-rule {
    match app-id="foot"
    tiled-state true
}

input {
    keyboard {
        xkb {
            layout "{{ .keyboard.layout }}"
        }
    }
}

layout {
    gaps {{ .layout.gaps }}
    background-color "#{{ .theme.base00 }}"
    border {
        width {{ .layout.border.width }}

        active-color "#{{ .theme.base0D }}"
        inactive-color "#{{ .theme.base03 }}"
        urgent-color "#{{ .theme.base08 }}"
    }
    focus-ring { off; }
}


binds {
    // Applications
    Mod+Return { spawn "{{ .terminal }}"; }
    Mod+D { spawn "fuzzel"; }

    // Close / quit
    Mod+Q { close-window; }
    Mod+Shift+E { quit; }


    // Focus HJKL
    {{ range $key := list "H" "J" "K" "L" }}

    Mod+{{ $key }} {
        {{ if or (eq $key "H") (eq $key "L") -}}
        focus-column-{{ template "direction" $key }};
        {{- else -}}
        focus-window-{{ template "direction" $key }};
        {{- end }}
    }

    Mod+Shift+{{ $key }} {
        {{ if or (eq $key "H") (eq $key "L") -}}
        move-column-{{ template "direction" $key }};
        {{- else -}}
        move-window-{{ template "direction" $key }};
        {{- end }}
    }

    Mod+Ctrl+{{ $key }} {
        focus-monitor-{{ template "direction" $key }};
    }

    Mod+Ctrl+Shift+{{ $key }} {
        move-column-to-monitor-{{ template "direction" $key }};
    }

    {{ end }}


    // Workspace navigation
    {{ range $key := list "U" "I" }}
    Mod+{{ $key }} {
        focus-workspace-{{ template "direction" $key }};
    }

    Mod+Ctrl+{{ $key }} {
        move-column-to-workspace-{{ template "direction" $key }};
    }
    {{ end }}


    // Numbered workspaces
    {{ range $i := iter 9 }}
    Mod+{{ $i }} {
        focus-workspace {{ $i }};
    }

    Mod+Ctrl+{{ $i }} {
        move-column-to-workspace {{ $i }};
    }
    {{ end }}


    // Column navigation
    Mod+Home { focus-column-first; }
    Mod+End { focus-column-last; }

    Mod+Ctrl+Home { move-column-to-first; }
    Mod+Ctrl+End { move-column-to-last; }


    // Consume / expel
    Mod+BracketLeft { consume-or-expel-window-left; }
    Mod+BracketRight { consume-or-expel-window-right; }
    Mod+Comma { consume-window-into-column; }
    Mod+Period { expel-window-from-column; }


    // Width
    Mod+R { switch-preset-column-width; }
    Mod+Shift+R { switch-preset-column-width-back; }

    Mod+Minus { set-column-width "-10%"; }
    Mod+Equal { set-column-width "+10%"; }


    // Height
    Mod+Shift+Minus { set-window-height "-10%"; }
    Mod+Shift+Equal { set-window-height "+10%"; }
    Mod+Ctrl+R { reset-window-height; }


    // Center
    Mod+C { center-column; }
    Mod+Ctrl+C { center-visible-columns; }


    // Fullscreen / maximize
    Mod+F { maximize-column; }
    Mod+Shift+F { fullscreen-window; }


    // Floating
    Mod+V { toggle-window-floating; }
    Mod+Shift+V { switch-focus-between-floating-and-tiling; }


    // Tabbed columns
    Mod+W { toggle-column-tabbed-display; }


    // Screenshots
    Print { screenshot; }
    Ctrl+Print { screenshot-screen; }
    Alt+Print { screenshot-window; }
}
{{ end }}
