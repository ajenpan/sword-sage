local coins = require("script.coins")
local player_restrict = require("script.player_restrict")
local chart = require("script.chart")
-- node: 由于'Each mod can only register once for every event', 所以需要一个集中注册点,在把事件分发到各个模块

LogI("start to init on_events.lua")

script.on_event(defines.events.on_research_finished, function (event)
  g_tm.on_research_finished(event)
  g_pf.on_research_finished(event)
end)

script.on_event(defines.events.on_player_died, function (event)
  g_fight_area.on_player_died(event)
  local player = game.get_player(event.player_index)
  g_ui.set_main_frame_visible(player, false)
end)

-- script.on_event(defines.events.on_chunk_generated, function (event)
-- end)

script.on_event(defines.events.on_space_platform_changed_state, function (event)
  -- 平台上限
  -- local platform = event.platform
  -- if event.old_state == 0 then
  -- local force = platform.force
  -- local hub = platform.hub
  -- if #force.platforms > storage.max_platform_count then
  --   hub.damage(100000000, "enemy")
  --   game.print(string.format("门派 [color=#ffff00]%s[/color] 平台超出限制", g_tm.get_team_name(force)))
  -- end
  -- end
end)

script.on_event(defines.events.on_entity_died, function (event)
  g_pf.on_entity_died(event)
  coins.on_entity_died(event)
end)

script.on_event(defines.events.on_space_platform_built_tile, function (event)
  player_restrict.on_platform_tile_check(event)
end)

-- 场景创建时触发
script.on_event(defines.events.on_game_created_from_scenario, function ()
  storage.forceInfos = storage.forceInfos or {}
  game.forces.player.share_chart = true
end)


script.on_event(defines.events.on_gui_click, function (event)
  local element = event.element

  -- filter
  if not (element and element.valid) then return end
  if #element.name < 1 then return end

  g_ui.on_gui_click(event)
  g_shop.on_gui_click(event)
  g_pf.on_gui_click(event)
  g_ptp.on_gui_click(event)
  g_uih.on_gui_click(event)
end)

-- 添加复选框状态改变事件处理
script.on_event(defines.events.on_gui_checked_state_changed, function (event)
  g_tm.on_gui_checked_state_changed(event)
end)

script.on_event(defines.events.on_gui_selected_tab_changed, function (event)
  g_ui.on_gui_selected_tab_changed(event)
end)

-- 玩家复活时触发
script.on_event(defines.events.on_player_respawned, function (event)
  -- local player = game.players[event.player_index]
  -- if player.force.name == "player" then
  --   ui.create_main_float_frame(player)
  -- end
end)

-- 当玩家退出
script.on_event(defines.events.on_player_left_game, function (event)
  g_ui.on_player_left_game(event)
  -- local player = game.players[event.player_index]
  -- ui.gui_xiaohui(player)
  -- game.print(string.format("[color=#ffff00]%s[/color] [color=#00ffff]%s[/color]%s 开始闭关修炼", g_tm.get_team_name(player.force), player.name, player.tag))
end)

script.on_event(defines.events.on_player_joined_game, function (event)
  LogI("on_player_joined_game", event)

  g_pm.on_player_joined_game(event)
  g_ui.on_player_joined_game(event)
  g_tm.on_player_joined_game(event)
end)

script.on_event(defines.events.on_player_left_game, function (event)
  local player = game.players[event.player_index]
  if not (player) then return end
  LogI("on_player_left_game", { pidx = event.player_index, name = player.name })

  g_tm.on_player_left_game(event)
end)

-- script.on_event(defines.events.on_entity_damaged, function (event)
--   g_pf.on_entity_damaged(event)
-- end)

-- script.on_event(defines.events.on_force_created	, function (event)
-- end)

script.on_event(g_custom_event.on_player_join_team, function (event)
  LogI("on_player_join_team", event)

  g_pm.on_player_join_team(event)
end)

-- 创建图层时触发
script.on_event(defines.events.on_surface_created, function (event)

end)

-- 1 second
script.on_nth_tick(60, function (event)
  g_tm.on_second(event)
  g_fight_area.on_second(event)
  g_mg.on_second(event)
end)

script.on_nth_tick(60 * 10, function (event)
  chart.on_10_second(event)
end)

-- 1 minute
script.on_nth_tick(60 * 60, function (event)
  g_pm.on_minute(event)
  g_tm.on_minute(event)
end)

-- 10 minutes
script.on_nth_tick(10 * 60 * 60, function (event)
  g_pf.on_10_minute(event)
end)

-- 1 hour
script.on_nth_tick(60 * 60 * 60, function (event)
  -- g_tm.remove_offline_players()
end)
