local utils = require("script.utils")

local function show_team_ship_list(event)
  local element = event.element
  local player = game.players[event.player_index]
  local force = game.forces[element.tags.force_index]
  if not force then
    player.print("门派不存在,id:" .. element.tags.force_index)
    return
  end

  local ship_list = {}
  for _, platform in pairs(force.platforms) do
    if (platform.surface) then
      table.insert(ship_list, { name = platform.name, weight = platform.weight, surrface_name = platform.surface.name })
    end
  end

  table.sort(ship_list, function (a, b) return a.weight > b.weight end)
  player.print("门派 [color=#ffff00]" .. g_tm.get_team_name(force) .. "[/color] 仙舟列表:")
  local total_weight = 0
  local ship_count = 0
  for _, ship in pairs(ship_list) do
    player.print((ship.weight / 1000) .. "吨☞[gps=0,0," .. ship.surrface_name .. "]")
    total_weight = total_weight + ship.weight / 1000
    ship_count = ship_count + 1
  end
  player.print("共" .. ship_count .. "艘" .. total_weight .. "吨")
end

-- 门派榜界面
local function create_team_rank_pane(frame, player)
  local has_team = (g_tm.get_team_info_by_index(player.force_index) ~= nil)

  local force_techs = {}
  local team_infos = g_tm.all_team_info()

  for _, team_info in pairs(team_infos) do
    local force = game.forces[team_info.force_index]

    local team_level = team_info.level


    if force then
      local tech_score = g_tm.get_technology_score(force)

      tech_score = tech_score * (team_level + 1) / 2 * team_level
      local tech_scorestr = utils.format_dd_count(tech_score)

      -- TODO: remove after v0.1.12
      if team_info.allow_join_checkbox_state then
        team_info.allow_others_join = team_info.allow_join_checkbox_state
        team_info.allow_join_checkbox_state = nil
      end

      table.insert(force_techs, {
        name = team_info.name,
        player_count = string.format("%d/%d", #force.connected_players, #force.players),
        force = force,
        index = team_info.force_index,
        tech_c = tech_scorestr,
        tech_score = tech_score,
        allow_join = team_info.allow_others_join,
      })
    else
      LogE("team disconnect forse", team_info)
    end
  end

  table.sort(force_techs, function (a, b) return a.tech_score > b.tech_score end)

  local pane = g_uih.add(frame, { type = "scroll-pane", vertical_scroll_policy = "auto", horizontal_scroll_policy = "never", style_table = { horizontally_stretchable = true, padding = { 5, 0, 5, 10 } } })

  local tab = g_uih.add(pane, { type = "table", column_count = 7, horizontal_scroll_policy = "never", vertical_scroll_policy = "auto-and-reserve-space", })
  -- 添加排序后的数据
  -- 总人数
  local total_player_count = 0
  -- 在线人数
  local all_online_player_count = 0
  for _, player in pairs(game.players) do
    total_player_count = total_player_count + 1
    if player.connected then
      all_online_player_count = all_online_player_count + 1
    end
  end
  tab.add{ type = "label", caption = "排名" }.style.width = 40
  tab.add{ type = "label", caption = "门派" }.style.width = 110
  tab.add{ type = "label", caption = "战力" }.style.width = 100
  tab.add{ type = "label", caption = "境界" }.style.width = 110
  tab.add{ type = "label", caption = "人数(" .. #game.connected_players .. "/" .. #game.players .. ")" }.style.width = 80
  tab.add{ type = "label", caption = "加入门派" }.style.width = 80
  tab.add{ type = "label", caption = "仙舟" }.style.width = 80

  for rank, item in ipairs(force_techs) do
    -- 排名
    tab.add{ type = "label", caption = "   " .. rank }.style.width = 40

    -- 生成队员名单提示文本
    local force = item.force
    local tooltip = "门派编号:" .. item.index .. "\n成员列表:"
    local player_list = {} -- 记录然后按离线时间排序
    for _, p in pairs(force.players) do
      -- 在线玩家
      if p.connected then
        table.insert(player_list, { name = p.name, time = 0, player = p })
      else
        -- 离线时长
        local time_diff = game.tick - p.last_online
        table.insert(player_list, { name = p.name, time = time_diff, player = p })
      end
    end
    -- 按离线时间排序
    local max_level_info = { name = "", level = 0 }
    table.sort(player_list, function (a, b) return a.time < b.time end)
    for _, p in pairs(player_list) do
      local ascension_cnt = g_pf.get_player_ascension_cnt(p.player)
      local tag = p.player.tag
      if ascension_cnt > max_level_info.level then
        max_level_info.level = ascension_cnt
        max_level_info.name = tag
      end
      if p.time > 0 then
        local hours = math.floor(p.time / 21600) / 10
        tooltip = tooltip .. "\n" .. "[离线" .. hours .. "小时]" .. p.name .. "[" .. tag .. "]"
      else
        tooltip = tooltip .. "\n" .. "[在线]" .. p.name .. "[" .. tag .. "]"
      end
    end

    -- 门派名（带提示）点击打印门派出生点位置
    tab.add{ type = "label", caption = item.name, tooltip = tooltip }.style.width = 110

    local value = (max_level_info.level + 1) / 2 * max_level_info.level
    local count = max_level_info.level
    local index = max_level_info.level

    -- 战斗力
    tab.add{ type = "label", caption = item.tech_c }

    -- 最高境界
    local sjlq = (index + 1) * index * 50
    local sjlq_ct = utils.format_dd_count(sjlq)
    tab.add{
      type = "label",
      caption = max_level_info.name,
      -- tooltip = "战力倍率:"
      --     .. value .. "00%"
      --     .. "\n制作速度:"
      --     .. (100 + (index - 1) * 50)
      --     .. "%\n挖掘速度:"
      --     .. (100 + (index - 1) * 50) .. "%"
      --     .. "\n当前渡劫所需灵气:" .. sjlq_ct
      --     .. "\n转生时可携带道具格数:" .. count
      --     .. "\n仙舟总数量上限:" .. (index + 3)
      --     .. "\n仙舟总吨位上限:" .. ((index * 100 + 3000) .. "吨"
      --       .. "\n最大闭关时间:" .. max_offline_m .. "小时")
    }.style.width = 120
    -- 人数
    tab.add{ type = "label", caption = item.player_count }.style.width = 60

    g_uih.add(tab, {
      type = "button",
      name = "join_team" .. force.index,
      on_click = g_tm.on_click_join_team,
      tags = { force_index = force.index },
      caption = "加入",
      enabled = not has_team and item.allow_join,
      style_table = { width = 60 }
    })

    local ship_list = {}
    for _, platform in pairs(force.platforms) do
      table.insert(ship_list, { name = platform.name, weight = platform.weight })
    end

    table.sort(ship_list, function (a, b) return a.weight > b.weight end)

    local tooltip2 = "仙舟列表:"
    local total_weight = 0
    local ship_count = 0
    for _, ship in pairs(ship_list) do
      local weight_str = (ship.weight / 1000) .. "吨"
      if ship.weight == 0 then weight_str = "[已炸]" end
      tooltip2 = tooltip2 .. "\n" .. weight_str .. "☞" .. ship.name
      total_weight = total_weight + ship.weight / 1000
      ship_count = ship_count + 1
    end

    g_uih.add(tab, { type = "button", name = "show_ship_list_" .. force.name, tags = { force_index = force.index }, caption = ship_count .. "艘", tooltip = tooltip2, on_click = show_team_ship_list })
  end
end

return {
  create_team_rank_pane = create_team_rank_pane,
}
