local terminal = "alacritty"
local fileManager = "nautilus"
local browser = "librewolf"
local launcher = "qs ipc call launcher toggle"
local wifiManager = "qs ipc call wifi toggle"
local displayLocker = "hyprlock"

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "intl",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 1,
		sensitivity = 0,

		touchpad = {
			natural_scroll = false,
		},
	},
})

-- Applications
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager))
hl.bind("SUPER + B", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + R", hl.dsp.exec_cmd(launcher))
hl.bind("SUPER + W", hl.dsp.exec_cmd(wifiManager))
hl.bind("SUPER + SHIFT + Escape", hl.dsp.exec_cmd(displayLocker))

-- Window management
hl.bind("SUPER + C", hl.dsp.window.close())
hl.bind("SUPER + M", hl.dsp.exit())
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen(0))

hl.bind("SUPER + Escape", hl.dsp.exec_cmd("qs ipc call bar toggle"))

hl.bind("SUPER + SHIFT + Backspace", hl.dsp.exec_cmd("poweroff"))

hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m output -o ~/screenshots"))

-- Focus movement
hl.bind("SUPER + H", hl.dsp.focus({ direction = "left" }))

hl.bind("SUPER + L", hl.dsp.focus({ direction = "right" }))

hl.bind("SUPER + K", hl.dsp.focus({ direction = "up" }))

hl.bind("SUPER + J", hl.dsp.focus({ direction = "down" }))

-- Workspaces
for i = 1, 10 do
	local key = i % 10

	hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))

hl.bind(
	"SUPER + SHIFT + S",
	hl.dsp.window.move({
		workspace = "special:magic",
	})
)

-- Workspace scrolling
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))

hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse movement/resizing
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })

hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume / brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)

hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)

hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)

hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
