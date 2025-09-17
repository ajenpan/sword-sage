local mod_res_path = "__sword-sage__/graphics/"
local base_res_path = "__base__/graphics"

local list = {
  {
    type = "sprite",
    name = "sprite_main_icon",
    filename = mod_res_path .. "main_icon_120.png",
    width = 120,
    height = 120,
  },
  {
    type = "sprite",
    name = "assign_points_sprite",
    filename = "__base__/graphics/icons/shapes/shape-cross.png",
    width = 64,
    height = 64,
    mipmap_count = 4,
  },
  {
    type = "sprite",
    name = "quality-normal",
    filename = "__base__/graphics/icons/quality-normal.png",
    width = 64,
    height = 64,
    flags = { "gui-icon" }
  },
  {
    type = "sprite",
    name = "quality-uncommon",
    filename = "__quality__/graphics/icons/quality-uncommon.png",
    width = 64,
    height = 64,
    flags = { "gui-icon" }
  },
  {
    type = "sprite",
    name = "quality-rare",
    filename = "__quality__/graphics/icons/quality-rare.png",
    width = 64,
    height = 64,
    flags = { "gui-icon" }
  },
  {
    type = "sprite",
    name = "quality-epic",
    filename = "__quality__/graphics/icons/quality-epic.png",
    width = 64,
    height = 64,
    flags = { "gui-icon" }
  },
  {
    type = "sprite",
    name = "quality-legendary",
    filename = "__quality__/graphics/icons/quality-legendary.png",
    width = 64,
    height = 64,
    flags = { "gui-icon" }
  },

}

data:extend(list)
