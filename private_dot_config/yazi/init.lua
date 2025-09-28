-- Highlight chezmoi-managed files in the file listing
-- The ◆ marker appears on the right side of each managed file/dir
--
-- Color variants to try (uncomment one):
require("chezmoi"):setup()                                                         -- cyan bold (default)
-- require("chezmoi"):setup({ style = ui.Style():fg("green"):bold(),   sign = "◆" }) -- green
-- require("chezmoi"):setup({ style = ui.Style():fg("magenta"):bold(), sign = "◆" }) -- magenta
-- require("chezmoi"):setup({ style = ui.Style():fg("yellow"):bold(),  sign = "◆" }) -- yellow
-- require("chezmoi"):setup({ style = ui.Style():fg("#FF875F"):bold(), sign = "◆" }) -- orange (256-color)
