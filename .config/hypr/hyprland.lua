hl.monitor({
	output = "preferred",
	mode = "highres",
	position = "auto",
	scale = 1.5,
})

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.on("hyprland.start", function()
	hl.exec_cmd("waybar")
	hl.exec_cmd("hyprpaper")
end)

require("style")
require("binds")

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 8,
		border_size = 2,
		layout = "dwindle",
		resize_on_border = false,
		allow_tearing = false,
		["col.active_border"] = "rgb(222130)",
		["col.inactive_border"] = "rgb(080808)",
	},
	dwindle = {
		preserve_split = true,
	},
	master = {
		new_status = "master",
	},
	misc = {
		force_default_wallpaper = -1,
		disable_hyprland_logo = true,
	},
	xwayland = {
		force_zero_scaling = true,
		use_nearest_neighbor = true,
	},
})

hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

hl.window_rule({
	match = {
		class = ".*",
	},
	tile = true,
})
