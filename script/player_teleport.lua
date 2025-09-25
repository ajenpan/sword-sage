local uih = require("script.ui_helper")
local pm = require("script.player_manager")

local ptp = {}

function ptp.set_teleport_enabled(player, enabled)
  g_pf.player_profile(player).teleport_enabled = enabled
end

function ptp.get_teleport_enabled(player)
  local enabled = g_pf.player_profile(player).teleport_enabled
  if enabled == nil then
    return true
  end
  return enabled
end

function ptp.create_teleport_button_list(player, rootelemnt)
  local frame = uih.add(rootelemnt, { type = "frame", name = "teleport_frame", direction = "horizontal" })
  local size_style = { width = 43, height = 38, }
  uih.add(frame, { type = "button", name = "teleport_button_nauvis", caption = "[planet=nauvis]", direction = "horizontal", tooltip = "传送到[planet=nauvis]", style_table = size_style })
  uih.add(frame, { type = "button", name = "teleport_button_vulcanus", caption = "[planet=vulcanus]", direction = "horizontal", tooltip = "传送到[planet=vulcanus]", style_table = size_style })
  uih.add(frame, { type = "button", name = "teleport_button_fulgora", caption = "[planet=fulgora]", direction = "horizontal", tooltip = "传送到[planet=fulgora]", style_table = size_style })
  uih.add(frame, { type = "button", name = "teleport_button_gleba", caption = "[planet=gleba]", direction = "horizontal", tooltip = "传送到[planet=gleba]", style_table = size_style })
  uih.add(frame, { type = "button", name = "teleport_button_aquilo", caption = "[planet=aquilo]", direction = "horizontal", tooltip = "传送到[planet=aquilo]", style_table = size_style })
end

function ptp.on_gui_click(event)
  local element = event.element
  if not (element and element.valid) then return end

  local player = game.players[event.player_index]
  if not player then return end

  if element.name == "teleport_button_nauvis" then
    ptp.teleport_to_planet(player, game.surfaces.nauvis)
  elseif element.name == "teleport_button_vulcanus" then
    ptp.teleport_to_planet(player, game.surfaces.vulcanus)
  elseif element.name == "teleport_button_fulgora" then
    ptp.teleport_to_planet(player, game.surfaces.fulgora)
  elseif element.name == "teleport_button_gleba" then
    ptp.teleport_to_planet(player, game.surfaces.gleba)
  elseif element.name == "teleport_button_aquilo" then
    ptp.teleport_to_planet(player, game.surfaces.aquilo)
  end
end

function ptp.teleport_to_planet(player, surface)
  if not ptp.get_teleport_enabled(player) then
    player.print("当前传送已被禁用")
    return
  end

  if surface == nil then
    player.print("星球不存在，无法传送!")
    return
  end

  if player.character == nil then
    player.print("此处没有玩家角色，无法传送!")
    return
  end

  if player.cargo_pod ~= nil then
    player.print("飞船中无法传送")
    return
  end

  if player.hub ~= nil then
    player.print("太空中无法传送")
    return
  end

  local spawn_position = player.force.get_spawn_position(surface)

  local entity = surface.find_entity("substation", spawn_position)
  if entity == nil then
    player.print("[gps=" .. spawn_position.x .. "," .. spawn_position.y .. "," .. surface.name .. "]没有[entity=substation]，无法传送")
    return
  end

  LogD("on player teleport_to_planet", { spawn_position = spawn_position, surface = surface.name })

  player.print(player.name .. player.tag .. "传送到[gps=" .. spawn_position.x .. "," .. spawn_position.y .. "," .. surface.name .. "]")
  -- surface.create_entity({ name = "big-explosion", position = spawn_position, force = player.force })
  player.teleport(spawn_position, surface)
end

return ptp
