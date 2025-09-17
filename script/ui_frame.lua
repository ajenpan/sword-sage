-- Generic GUI stuff goes here.

GENERIC_GUI_MAX_HEIGHT = 500


local utils = require("script.utils")
local uih = require("script.ui_helper")
local ptp = require("script.player_teleport")

local ui = {
  register_tabbed = {}
}


function ui.on_init()
  ui.register_tabbed = {}
end

local frame_cfg = {
  frame_name = "main_frame",
  frame_caption = "系统面板",
}

function ui.create_note_pane(tabbed_pane, player)
  local text = ""
  text = text .. "⚠注意: mod正在开发中, 有什么想法可以跟服主讲.\n\n"

  text = text .. "常用命令: \n"
  text = text .. "▶输入 玩家: 显示在线玩家\n"
  text = text .. "▶输入「钓鱼」「伐木」「采矿」「采药」:  看概率获得物品\n"
  text = text .. "▶输入「捕猎」: 解锁[虫卵处理]科技 ,  并随机获得虫卵\n"


  local textfield = tabbed_pane.add{ type = "text-box", text = text, }
  textfield.style.horizontally_stretchable = true
  textfield.style.vertically_stretchable = true
  textfield.read_only = true
  textfield.style.width = 660
end

function ui.register_tabbed_pane(name, caption, create_fn)
  ui.register_tabbed[#ui.register_tabbed + 1] = {
    name = name,
    caption = caption,
    create_fn = create_fn,
  }
end

function ui.create_registered_tabbed_pane(tabbed_pane, player)
  for i, item in ipairs(ui.register_tabbed) do
    local tab_name = item.name .. "_tab"
    local pane_name = item.name .. "_pane"

    local tab = tabbed_pane[tab_name]
    local pane = tabbed_pane[pane_name]
    if tab == nil then
      tab = tabbed_pane.add{ type = "tab", name = tab_name, caption = item.caption }
      pane = tabbed_pane.add{ type = "scroll-pane", name = pane_name, horizontal_scroll_policy = "never", vertical_scroll_policy = "auto-and-reserve-space" }

      tabbed_pane.add_tab(tab, pane)
    end
    pane.clear()
    item.create_fn(pane, player)
  end
end

function ui.create_main_float_frame(player)
  local float_frame = player.gui.top["main_float_frame"]
  if float_frame == nil then
    float_frame = player.gui.top.add{ name = "main_float_frame", type = "flow", direction = "horizontal" }
  end
  float_frame.clear()
  uih.add(float_frame, { name = "frame_toggle_btn", type = "sprite-button", sprite = "sprite_main_icon", tooltip = "打开系统", style_table = { size = { 80, 80 } } })
  ptp.create_teleport_button_list(player, float_frame)
end

function ui.create_frame(player)
  if player.gui.screen[frame_cfg.frame_name] ~= nil then
    player.gui.screen[frame_cfg.frame_name].destroy()
    player.gui.screen[frame_cfg.frame_name] = nil
  end

  local frame = player.gui.screen.add{ type = "frame", name = frame_cfg.frame_name, direction = "vertical" }
  frame.force_auto_center()

  local title_flow = frame.add{ type = "flow", direction = "horizontal" }
  title_flow.style.horizontally_stretchable = true
  title_flow.style.horizontal_spacing = 8
  title_flow.style.height = 24

  title_flow.add{ type = "label", caption = frame_cfg.frame_caption, style = "frame_title" }.style.minimal_width = 28
  local filler = title_flow.add{ type = "empty-widget", style = "draggable_space_header" }
  filler.style.horizontally_stretchable = true
  filler.style.size = { 600, 24 }
  filler.drag_target = frame


  uih.add(title_flow, {
    name = "bnt_close_uiframe",
    type = "sprite-button",
    sprite = "utility/close_black",
    style = "shortcut_bar_button",
    style_table = { size = { 32, 24 } },
  })


  local tabbed_pane = frame.add{ type = "tabbed-pane" }
  tabbed_pane.selected_tab_index = 1
  tabbed_pane.style.maximal_height = 500

  ui.create_registered_tabbed_pane(tabbed_pane, player)

  ui.player_storage(player).ui_frame = frame
end

function ui.player_storage(player)
  if storage.uiframe == nil then
    storage.uiframe = {}
  end
  if storage.uiframe[player.index] == nil then
    storage.uiframe[player.index] = {}
  end
  return storage.uiframe[player.index]
end

function ui.destroy_teleport_button_list(player)
  if player.gui.top["teleport_frame"] then
    player.gui.top["teleport_frame"].destroy()
  end
end

function ui.toggle_main_frame_visible(event)
  local player = game.players[event.player_index]
  ui.set_main_frame_visible(player, player.gui.screen[frame_cfg.frame_name] == nil)
end

function ui.set_main_frame_visible(player, visible)
  if not player then return end

  if (visible) then
    if not (player.character and player.character.valid) then
      return
    end
    ui.create_frame(player)
  else
    local ui_frame = ui.player_storage(player).ui_frame
    if ui_frame == nil then
      return
    end
    ui_frame.destroy()
    ui.player_storage(player).ui_frame = nil
  end
end

function ui.on_gui_click(event)
  local element = event.element
  if not (element and element.valid) then return end
  local player = game.players[event.player_index]
  if #element.name < 1 then
    return
  end
  if player == nil then return end

  if element.name == "frame_toggle_btn" then
    ui.toggle_main_frame_visible(event)
  elseif element.name == "bnt_close_uiframe" then
    ui.set_main_frame_visible(player, false)
  end
end

return ui
