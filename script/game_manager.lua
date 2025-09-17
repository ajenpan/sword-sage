-- registry custom event
g_custom_event = {
  on_player_left_team = script.generate_event_name(),
  on_player_join_team = script.generate_event_name(),
  on_team_created = script.generate_event_name(),
  on_team_destroy = script.generate_event_name(),
}

-- load all script
require("script.logger")
require("script.on_events")
require("script.command")

g_pm = require("script.player_manager")
g_fight_area = require("script.fight_area")
g_tm = require("script.team_manager")
g_trank = require("script.team_rank")
g_utils = require("script.utils")
g_shop = require("script.shop")
g_pf = require("script.player_profile")
g_uih = require("script.ui_helper")
g_ptp = require("script.player_teleport")
g_ui = require("script.ui_frame")
g_mg = require("script.map_gen")

SwordSageDebugMod = false
LogLevel = LogLevelEnum.Info

GM_INIT = false

local function on_init(event)
  if GM_INIT then
    return
  end
  GM_INIT = true
  LogI("game manager init")
  game.technology_notifications_enabled = false
  game.forces.player.share_chart = true

  g_tm.on_init()
  g_pf.on_init()
  g_mg.on_init()
end

local function init_gui()
  g_ui.on_init()
  g_ui.register_tabbed_pane("profile", "角色", g_pf.create_profile_pane)
  g_ui.register_tabbed_pane("teaminfo", "门派", g_tm.create_gui_pane)
  g_ui.register_tabbed_pane("teamrank", "门派榜", g_trank.create_team_rank_pane)
  g_ui.register_tabbed_pane("shop", "百宝阁", g_shop.create_shop_pane)
  g_ui.register_tabbed_pane("note", "指南", g_ui.create_note_pane)
  g_ui.register_tabbed_pane("fight_area", "镇妖塔", g_fight_area.create_gui_pane)
end

init_gui()

return {
  on_init = on_init
}
