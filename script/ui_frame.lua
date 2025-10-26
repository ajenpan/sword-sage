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
  text = text .. "⚠注意: mod正在开发中, 有什么建议想法可以跟服主讲.qq群: 126849387 \n\n"

  text = text .. "常用命令: \n"
  text = text .. "▶输入 玩家: 显示在线玩家\n"
  text = text .. "▶输入「钓鱼」「伐木」「采矿」「采药」:  看概率获得物品\n"
  text = text .. "▶输入「捕猎」: 解锁[虫卵处理]科技 ,  并随机获得虫卵\n"
  text = text .. "版本更新计划:"
  text = text .. "完善镇妖塔连胜机制"

  local pane = uih.add(tabbed_pane, { type = "scroll-pane", vertical_scroll_policy = "auto", horizontal_scroll_policy = "never", style_table = { horizontally_stretchable = true, padding = { 5, 0, 5, 10 } } })

  local textfield = pane.add{ type = "text-box", text = text, }
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
    tab_element = nil,
    pane_element = nil,
  }
end

function ui.create_registered_tabbed_pane(tabbed_pane, player)
  local s = ui.player_storage(player)
  if s.main_tabbed_pane == nil then
    s.main_tabbed_pane = {}
  end

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
    -- pane.clear()
    -- item.create_fn(pane, player)
    -- item.tab_element = tab
    -- item.pane_element = pane
    s.main_tabbed_pane[i] = {
      tab_element = tab,
      pane_element = pane,
    }
  end
end

function ui.reopen_tabbed_pane(tab_index, player)
  local uis = ui.player_storage(player)
  -- if uis.main_tabbed_pane_selected_tab_index == tab_index then
  --   return
  -- end
  uis.main_tabbed_pane_selected_index = tab_index
  local tabbed_pane = uis.main_tabbed_pane
  if not (tabbed_pane and tabbed_pane[tab_index]) then return end
  local pane = tabbed_pane[tab_index].pane_element
  pane.clear()
  ui.register_tabbed[tab_index].create_fn(pane, player)
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

function ui.destory_main_float_frame(player)
  local float_frame = player.gui.top["main_float_frame"]
  if (float_frame == nil) then return end
  float_frame.destroy()
end

function ui.destory_main_frame(player)
  if player.gui.screen[frame_cfg.frame_name] ~= nil then
    player.gui.screen[frame_cfg.frame_name].destroy()
  end
end

function ui.create_frame(player)
  ui.destory_main_frame(player)

  local frame = player.gui.screen.add{ type = "frame", name = frame_cfg.frame_name, direction = "vertical" }
  frame.force_auto_center()
  frame.visible = false

  local title_flow = uih.add(frame, { type = "flow", direction = "horizontal", style_table = { horizontally_stretchable = true, horizontal_spacing = 8, height = 24 } })
  uih.add(title_flow, { type = "label", caption = frame_cfg.frame_caption, style = "frame_title", style_table = { minimal_width = 28 } })
  uih.add(title_flow, { type = "empty-widget", style = "draggable_space_header", style_table = { horizontally_stretchable = true, size = { 600, 24 } } }).drag_target = frame
  uih.add(title_flow, { type = "flow", direction = "horizontal", style_table = { horizontal_align = "right", width = 30 } })
  uih.add(title_flow, { type = "sprite-button", name = "bnt_close_uiframe", sprite = "utility/close_black", style = "shortcut_bar_button", style_table = { size = { 32, 24 } } })

  local tabbed_pane = frame.add{ type = "tabbed-pane", name = "main-tabbed-pane" }
  tabbed_pane.selected_tab_index = 1
  tabbed_pane.style.maximal_height = 500

  ui.create_registered_tabbed_pane(tabbed_pane, player)
  ui.reopen_tabbed_pane(1, player)

  return frame
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
  local visible = true
  if player.gui.screen[frame_cfg.frame_name] then
    visible = not player.gui.screen[frame_cfg.frame_name].visible
  end
  ui.set_main_frame_visible(player, visible)
end

function ui.set_main_frame_visible(player, visible)
  if not player then return end
  local ui_frame = player.gui.screen[frame_cfg.frame_name]
  if (visible) then
    if ui_frame == nil then
      ui_frame = ui.create_frame(player)
    end
    ui_frame.visible = true
    local uis = ui.player_storage(player)
    ui.reopen_tabbed_pane(uis.main_tabbed_pane_selected_index or 1, player)
  else
    if ui_frame == nil then
      return
    end
    ui_frame.visible = false
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

function ui.on_gui_selected_tab_changed(event)
  local element = event.element
  if not (element and element.valid) then return end
  local player = game.players[event.player_index]
  if not (player) then return end

  if element.name == "main-tabbed-pane" then
    ui.reopen_tabbed_pane(element.selected_tab_index, player)
  end
end

function ui.on_player_joined_game(event)
  local player = game.players[event.player_index]
  if not (player) then return end
  ui.create_main_float_frame(player)
  ui.create_frame(player)
end

function ui.on_player_left_game(event)
  local player = game.players[event.player_index]
  if not (player) then return end

  ui.destory_main_float_frame(player)
  ui.destory_main_frame(player)
end

return ui
