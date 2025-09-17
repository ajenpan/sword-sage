local mg = require("script.map_gen")
local uih = require("script.ui_helper")
local utils = require("script.utils")

local tm = {}

function tm.on_init()
  if storage.team == nil then
    storage.team = {}
  end
  for i, info in pairs(storage.team) do
    LogI("teaminfo:", info)
  end
end

-- 门派名是否存在
function tm.is_team_name_exist(name)
  local teams = tm.all_team_info()
  for _, team in pairs(teams) do
    if team.team_name == name then
      return true
    end
  end
  return false
end

function tm.all_team_info()
  if storage.team == nil then
    storage.team = {}
  end
  return storage.team
end

function tm.get_team_info_by_index(forceindex)
  if storage.team == nil then
    storage.team = {}
  end
  return storage.team[forceindex]
end

function tm.get_team_name(force)
  local team = tm.get_team_info_by_index(force.index)
  if team == nil then
    return ""
  end
  return team.name
end

function tm.get_team_info(player)
  return tm.get_team_info_by_index(player.force.index)
end

-- local SetForceDistance = function (force)
--   if storage.force_distance == nil then
--     storage.force_distance = 20
--   end
--   force.character_build_distance_bonus = storage.force_distance
--   force.character_item_drop_distance_bonus = storage.force_distance
--   force.character_reach_distance_bonus = storage.force_distance
--   force.character_resource_reach_distance_bonus = storage.force_distance
--   force.character_item_pickup_distance_bonus = storage.force_distance
--   force.character_loot_pickup_distance_bonus = storage.force_distance
-- end

-- 打印离线团队
-- local PrintForce = function ()
--   local list = {}
--   for _, info in pairs(storage.forceInfos) do
--     local force = info.force
--     local min_offline_m = 0
--     for _, player in pairs(force.players) do
--       if not player.connected then
--         local offline_time = (game.tick - player.last_online) / 60 / 60 / 60
--         if min_offline_m == 0 or min_offline_m > offline_time then
--           min_offline_m = offline_time
--         end
--       else
--         min_offline_m = 0
--         break
--       end
--     end
--     if min_offline_m > 0 then
--       table.insert(list, { info = info, offline_time = min_offline_m })
--     end
--   end
--   table.sort(list, function (a, b) return a.offline_time < b.offline_time end)
--   for _, info in pairs(list) do
--     game.print(string.format("编号:%d 门派:%s 离线时间: %.2f小时", info.info.index, info.info.name, info.offline_time))
--   end
-- end

local function get_new_team_id()
  local all_team_infos = tm.all_team_info()
  local usesd_index = {}
  local team_id = 1

  for _, team_info in pairs(all_team_infos) do
    usesd_index[team_info.team_id] = true
  end

  while true do
    if usesd_index[team_id] then
      team_id = team_id + 1
    else
      break
    end
  end
  return team_id
end

tm.get_new_team_id = get_new_team_id

local function create_team_force(player, team_name)
  local force_name = "player" .. player.index
  log("create_team_force force_name:" .. force_name)

  local force = game.forces[force_name]
  if (force) then
    player.print("当前门派尚未销毁, 请等1分钟")
    return
  end

  local ascension_cnt = g_pf.get_player_ascension_cnt(player)
  force = game.create_force(force_name)
  player.force = force

  local spawn_surface = player.surface.name

  -- 禁用重炮
  force.technologies["artillery"].enabled = false
  force.technologies["artillery-shell-damage-1"].enabled = false
  force.technologies["artillery-shell-range-1"].enabled = false
  force.technologies["artillery-shell-speed-1"].enabled = false
  force.technologies["atomic-bomb"].enabled = false

  if spawn_surface ~= "nauvis" then
    force.technologies["oil-processing"].researched = true
    force.technologies["advanced-oil-processing"].enabled = true
    force.technologies["space-platform-thruster"].researched = true
  end

  if spawn_surface == "fulgora" then
    force.technologies["planet-discovery-fulgora"].researched = true  -- 发现星球
    force.technologies["advanced-oil-processing"].researched = true   -- 高级石油处理
    force.technologies["electronics"].researched = true               -- 电子学
  elseif spawn_surface == "vulcanus" then
    force.technologies["planet-discovery-vulcanus"].researched = true -- 发现星球
    force.technologies["steel-processing"].researched = true          -- 钢铁冶炼
    force.technologies["oil-gathering"].researched = true             -- 石油采集
    force.technologies["solar-energy"].researched = true              -- 太阳能
    force.technologies["lubricant"].researched = true                 -- 润滑油
    force.technologies["concrete"].researched = true                  -- 混凝土
    force.technologies["advanced-oil-processing"].researched = true   -- 高级石油处理
  elseif spawn_surface == "gleba" then
    force.technologies["planet-discovery-gleba"].researched = true    -- 发现星球
  end

  force.share_chart = true
  force.set_friend(game.forces.player, true)
  game.forces.player.set_friend(force, true)
  force.set_cease_fire(game.forces.player, true)
  game.forces.player.set_cease_fire(force, true)

  local team_id = get_new_team_id()

  local pos = mg.get_team_area_pos(team_id)
  local is_chunk_generated = mg.is_team_area_chunk_generated(pos)
  if is_chunk_generated then
    mg.create_team_area(force, pos)
  else
    if storage.delay_spawn_players == nil then
      storage.delay_spawn_players = {}
    end
    storage.delay_spawn_players[player.index] = {
      start_at = game.tick,
      player = player
    }
  end

  local teaminfo = {}
  teaminfo.team_id = team_id
  teaminfo.name = team_name
  teaminfo.force_index = force.index
  teaminfo.spawn_position = pos
  teaminfo.level = ascension_cnt
  teaminfo.allow_others_join = false
  teaminfo.spawn_surface_name = spawn_surface
  teaminfo.owner_player_index = player.index
  teaminfo.is_chunk_generated = is_chunk_generated
  teaminfo.create_at = game.tick
  teaminfo.max_lifespan = 6 * TICKS_PER_HOUR + 12 * ascension_cnt * TICKS_PER_HOUR
  teaminfo.online_state = "online"
  teaminfo.online_state_change_at = game.tick

  tm.all_team_info()[force.index] = teaminfo

  force.set_spawn_position(pos, game.surfaces.nauvis)
  force.set_spawn_position(pos, game.surfaces.fulgora)
  force.set_spawn_position(pos, game.surfaces.vulcanus)
  force.set_spawn_position(pos, game.surfaces.gleba)
  force.set_spawn_position(pos, game.surfaces.aquilo)

  script.raise_event(g_custom_event.on_player_join_team, { player_index = player.index, tick = game.tick, force_index = force.index })

  -- tech bonus
  tm.unlock_tech_by_ascension(player)

  if is_chunk_generated then
    player.print("传送到[gps=" .. pos.x .. "," .. pos.y .. "]")
    player.teleport(force.get_spawn_position(player.surface))
  end
  return force
end

function tm.create_new_team(player, team_name)
  local force = create_team_force(player, team_name)

  if (force == nil) then
    return false
  end

  game.print("道友 [color=#00ffff]" .. player.name .. "[/color] 创建了 门派 [color=#ffff00]" .. team_name .. "[/color]")

  -- local index = math.min( g_pf.get_player_ascension_cnt(player)(player), 100) -- 合并数值限制
  -- local modifier = (index - 1) * 0.5
  return true
end

function tm.destroy_team(teaminfo)
  if (teaminfo == nil) then return end
  local force = game.forces[teaminfo.force_index]
  if (force == nil) then return end

  LogI("on_destroy_team:", teaminfo)

  local name = teaminfo.name
  game.print("门派 [color=#ffff00]" .. name .. "[/color] 湮灭于 [color=#ff00ff]归墟[/color]")

  for _, player in pairs(force.players) do
    -- game.print("道友 [color=#00ffff]" .. player.name .. "[/color] 转生")
    -- 清空玩家背包
    player.clear_items_inside()
    player.force = game.forces.player
    if g_pf.get_player_ascension_cnt(player) == 1 then
      player.teleport({ 0, 0 }, game.surfaces.nauvis)
    else
      player.teleport({ 0, 0 }, player.surface)
    end
  end

  g_mg.destroy_team_area(teaminfo.spawn_position)
  tm.all_team_info()[force.index] = nil

  for _, platform in pairs(force.platforms) do
    platform.destroy()
  end

  force.reset()
  game.merge_forces(force, game.forces.player)
end

function tm.on_research_finished(event)
  local research = event.research
  local teaminfo = tm.get_team_info_by_index(research.force.index)
  if teaminfo == nil then return end

  -- LogD("tm.on_research_finished ", { teamname = teaminfo.name, researchname = research.name })

  local add_team_lifespan_map = {
    ["promethium-science-pack"] = 6,
    ["cryogenic-science-pack"] = 6,
    ["agricultural-science-pack"] = 6,
    ["electromagnetic-science-pack"] = 6,
    ["metallurgic-science-pack"] = 6,
    ["space-science-pack"] = 6,
    ["chemical-science-pack"] = 6,
    ["logistic-science-pack"] = 6,
    ["automation-science-pack"] = 6,
  }

  if add_team_lifespan_map[research.name] then
    teaminfo.max_lifespan = teaminfo.max_lifespan + 6 * TICKS_PER_HOUR
  end
end

local function update_team_online_sate(player)
  local team_info = tm.get_team_info(player)
  if team_info == nil then return end

  local force = game.forces[player.force_index]
  if force == nil then return end

  team_info.online_state_change_at = game.tick

  if #force.connected_players == 0 then
    team_info.online_state = "offline"
  else
    team_info.online_state = "online"
  end
end

function tm.on_player_joined_game(event)
  local player = game.players[event.player_index]
  if (player == nil) then return end
  update_team_online_sate(player)
end

function tm.on_player_left_game(event)
  local player = game.players[event.player_index]
  if (player == nil) then return end
  update_team_online_sate(player)
end

function tm.on_second(event)
  if storage.delay_spawn_players then
    for i, waitinfo in pairs(storage.delay_spawn_players) do
      local player = waitinfo.player
      local info = tm.get_team_info(player)
      if info == nil then
        storage.delay_spawn_players[i] = nil
      else
        local pos = player.force.get_spawn_position(player.surface)
        local is_chunk_generated = mg.is_team_area_chunk_generated(pos)
        if is_chunk_generated then
          mg.create_team_area(player.force, pos)
          player.teleport(pos, player.surface)
          storage.delay_spawn_players[i] = nil
        end
      end
    end
  end

  local all_team_infos = tm.all_team_info()
  for _, info in pairs(all_team_infos) do
    local force = game.forces[info.force_index]

    if not force then
      LogW("froce not found", info)
      goto continue
    end

    local is_out_lifespan = false
    local is_zero_players = #force.players < 1

    if info.online_state and info.online_state == "offline" then
      local offline_at = info.online_state_change_at
      local offline_span = event.tick - offline_at
      is_out_lifespan = (offline_span > info.max_lifespan)
    end

    if is_out_lifespan or is_zero_players then
      local reason = ""
      if is_out_lifespan then
        reason = "寿命耗尽"
      elseif is_zero_players then
        reason = "没有玩家"
      end

      game.print(string.format("开始销毁门派:%s,原因:%s", info.name, reason))

      tm.destroy_team(info)
    end

    ::continue::
  end
end

function tm.on_minute(event)

end

-- 检测是否在自己区域
function tm.is_in_force_area(entity)
  return true
  -- if not entity.valid then return true end
  -- local check_surfaces = { "nauvis", "fulgora", "vulcanus", "gleba", "aquilo" }
  -- local is_check = false
  -- for _, surface_name in pairs(check_surfaces) do
  --   if entity.surface.name == surface_name then
  --     is_check = true
  --     break
  --   end
  -- end
  -- if not is_check then
  --   return true
  -- end

  -- -- todo:
  -- local force = entity.force
  -- local forceInfo = storage.forceInfos[force.name]
  -- if forceInfo then
  --   local respawn_pos = forceInfo.spawn_position
  --   if entity.position.x >= respawn_pos.x - map_info.size / 2 and entity.position.x < respawn_pos.x + map_info.size / 2 and entity.position.y >= respawn_pos.y - map_info.size / 2 and entity.position.y < respawn_pos.y + map_info.size / 2 then
  --     return true
  --   end
  -- end
  -- return false
end

-- 玩家移动时调用
script.on_event(defines.events.on_player_changed_position, function (event)
  local player = game.get_player(event.player_index)

  -- TODO:
  if not player or not player.character then return end
  if player.controller_type ~= defines.controllers.character then return end          -- 不是玩家
  if player.physical_controller_type ~= defines.controllers.character then return end -- 不是玩家
  if player.admin then return end

  -- 检查玩家包裹是否为空或者只有1个物品(穿了衣服)
  if player.get_item_count() <= 1 then
    return
  end

  if not tm.is_in_force_area(player.character) then
    local team_info = tm.get_team_info_by_index(player.force.index)
    local spawn_surface = team_info and game.surfaces[team_info.spawn_surface_name] or nil
    if team_info and spawn_surface then
      player.print("▣ 你已离开门派区域，将被传送回门派出生点 ▣")
      player.teleport(team_info.spawn_position, spawn_surface)
    end
  end
end)


function tm.on_gui_checked_state_changed(event)
  local element = event.element
  local player = game.players[event.player_index]
  if element.name == "allow_join_checkbox" then
    local team_info = tm.get_team_info_by_index(player.force_index)
    if team_info == nil then
      return
    end

    team_info.allow_join_checkbox_state = element.state
    if element.state then
      game.print(string.format("门派 [color=#ffff00]%s[/color] 开始招收弟子", team_info.name))
    else
      game.print(string.format("门派 [color=#ffff00]%s[/color] 停止招收弟子", team_info.name))
    end
  end
end

function tm.create_gui_pane(frame, player)
  if not (player.character and player.character.valid) then return end

  local uistorage = g_ui.player_storage(player)
  local profile = g_pf.player_profile(player)
  local team_info = tm.get_team_info_by_index(player.force_index)
  local has_team = (team_info ~= nil)
  local is_team_owner = team_info and team_info.owner_player_index == player.index or false

  local pane = uih.add(frame, { type = "scroll-pane", vertical_scroll_policy = "auto", horizontal_scroll_policy = "never", style_table = { padding = { 5, 0, 5, 10 } } })

  if not has_team then
    local flow = uih.add(pane, { type = "flow", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto-and-reserve-space" })

    uih.add(flow, { type = "label", caption = "创建门派:", style_table = { font = "font_default_18" } })
    uistorage.create_team_name_field = uih.add(flow, { type = "textfield", name = "create_team_name_field", text = "门派名", style_table = { width = 120 } })
    uih.add(flow, {
      type = "button",
      name = "create_team_confirm_btn",
      on_click = tm.on_click_create_team_confirm_btn,
      caption = "确认",
      style = "confirm_button_without_tooltip",
      style_table = { minimal_width = 40 }
    })
    return
  end

  uih.add(pane, { type = "line" })

  uih.add(
  -- parant
    uih.add(pane, { type = "flow", direction = "horizontal" }),
    -- children
    {
      -- team name
      { type = "label", caption = "门派:" .. (team_info and team_info.name or "无"), style_table = { font = "font_default_18" } },
      { type = "flow", direction = "horizontal", style_table = { horizontally_stretchable = true } },
      { type = "flow", direction = "horizontal", style_table = { horizontal_align = "right", width = 200 } },
      -- allow others join team
      { type = "checkbox", name = "allow_join_checkbox", caption = "允许他人加入本门派", state = team_info and team_info.allow_others_join or false, visible = is_team_owner, style_table = { minimal_width = 80 } },
      -- quit team
      { type = "button", caption = "退出门派", name = "tm.btn_leave_team_btn", on_click = tm.on_click_leave_team_btn, visible = has_team, style_table = { minimal_width = 20 } }
    }
  )

  uih.add(pane, { type = "line" })

  -- uih.add(
  --   uih.add(pane, { type = "flow", direction = "horizontal", style_table = { vertical_align = "center" } }),
  --   { { type = "label", caption = "飞升" }, { type = "line" } }
  -- )

  uih.add(
    uih.add(pane, { type = "flow", direction = "horizontal" }),
    {
      { type = "label", caption = "掌门等级大于10,到达星系边缘[space-location=solar-system-edge]可解锁飞升", style_table = { font = "font_default_18" } },
      { type = "flow", direction = "horizontal", style_table = { horizontally_stretchable = true } },
      { type = "flow", direction = "horizontal", style_table = { horizontal_align = "right", width = 200 } },
      { type = "button", caption = "门派飞升", name = "tm.btn_team_ascension", on_click = tm.on_click_ascension_confirm_btn, enabled = (profile.level >= 10 and is_team_owner), style_table = { minimal_width = 20 } }
    }
  )

  uih.add(pane, { type = "line" })
  uih.add(pane, { type = "label", caption = "成员列表: (待开发中)" })
end

function tm.on_gui_click(event)
  -- if not (event.element and event.element.valid) then return end
  -- local element = event.element
  -- local player = game.players[event.player_index]
  -- if element.name == "create_team_confirm_btn" then
  --   tm.on_click_create_team_confirm_btn(event, player)
  -- end
end

function tm.get_technology_score(force)
  local score = 0
  for name, tech in pairs(force.technologies) do
    if tech.researched then
      -- item.
      -- local tech_p = prototypes.technology[name]
      score = score + tech.research_unit_count * #tech.research_unit_ingredients
    end
  end
  return score
end

function tm.get_online_players(force)
  local players = {}
  for _, player in pairs(force.players) do
    if player.connected then
      players[#players + 1] = player
    end
  end
  return players
end

function tm.on_click_create_team_confirm_btn(event)
  local player = game.players[event.player_index]

  local team_name = g_ui.player_storage(player).create_team_name_field.text

  if #team_name > 64 then
    player.print("你的门派名太长了")
    return false
  end
  if #team_name <= 0 then
    player.print("门派不能为空")
    return false
  end

  if tm.is_team_name_exist(team_name) then
    player.print("门派名称已存在，请重新输入")
    return false
  end

  if tm.create_new_team(player, team_name) then
    g_ui.set_main_frame_visible(player, false)
  end
end

function tm.on_click_join_team(event)
  local element = event.element
  local player = game.players[element.player_index]
  if player.character == nil then
    player.print("没有玩家角色，无法加入门派")
    return
  end

  local team_info = tm.get_team_info_by_index(element.tags.force_index)
  if team_info == nil then
    player.print("门派不存在，无法加入门派")
    return
  end

  local force = game.forces[element.tags.force_index]
  game.print("[color=#00ffff]" .. player.name .. "[/color] 加入了门派 [color=#ffff00]" .. team_info.name .. "[/color]")
  player.force = force

  -- 传送到门派出生点
  local surface = "nauvis"
  if team_info.spawn_surface_name then
    surface = team_info.spawn_surface_name
  end

  player.teleport(team_info.spawn_position, surface)
  -- local index =  g_pf.get_player_ascension_cnt(player)(player)
  -- player.character_crafting_speed_modifier = (index - 1) * 0.5
  -- player.character_mining_speed_modifier = (index - 1) * 0.5
  g_ui.set_main_frame_visible(player, false)

  script.raise_event(g_custom_event.on_player_join_team, { tick = game.tick, player_index = player.index, cause = "byself" })
end

function tm.on_player_left_team(event)
end

function tm.on_click_leave_team_btn(event)
  local player = game.players[event.element.player_index]
  if not (player and player.character and player.character.valid) then
    return
  end

  local team_info = tm.get_team_info_by_index(player.force_index)
  if not team_info then
    return
  end

  g_ui.set_main_frame_visible(player, false)

  player.clear_items_inside()

  -- if player.character ~= nil and player.character.valid then
  -- player.character.die()
  -- end

  player.force = game.forces.player
  player.teleport(player.force.get_spawn_position(player.surface))

  game.print("道友 [color=#00ffff]" .. player.name .. "[/color] 自刎离开了门派 [color=#ffff00]" .. team_info.name .. "[/color]")

  script.raise_event(g_custom_event.on_player_left_team, { tick = game.tick, player_index = player.index, cause = "byself" })

  update_team_online_sate(player)

  -- 如果是 掌门离开 门派? 是否需要把门派清空?
end

function tm.on_click_ascension_confirm_btn(event)
  local player = game.players[event.player_index]
  if not (player and player.character and player.character.valid) then
    return
  end
  tm.do_ascension(player)
end

function tm.do_ascension(player)
  if not (player and player.character and player.character.valid) then
    return
  end

  if player.character.surface.platform == nil or
      player.character.surface.platform.space_location == nil then
    player.print("玩家未处于仙舟内，无法转生")
    return
  end

  local teaminfo = tm.get_team_info(player)
  if teaminfo == nil then
    player.print("获取门派信息失败")
    return
  end

  local profile = g_pf.player_profile(player)

  g_ui.set_main_frame_visible(player, false)
  teaminfo.allow_others_join = false

  profile.ascension_cnt = profile.ascension_cnt + 1
  profile.level = 1
  profile.xp = 0
  profile.usable_ap = profile.usable_ap + 5

  player.tag = g_pf.get_player_title(g_pf.get_player_ascension_cnt(player))

  local count = profile.ascension_cnt
  local spawn_surface = teaminfo.spaspawn_surface_name
  player.force = game.forces.player

  -- 随机一个
  local surface_names = { "nauvis", "fulgora", "vulcanus", "gleba" }
  for i, name in pairs(surface_names) do
    if name == spawn_surface then
      surface_names[i] = nil
      break
    end
  end

  local surface_name = surface_names[math.random(1, #surface_names)]
  player.character.teleport({ x = 0, y = 0 }, game.surfaces[surface_name])

  -- 记录玩家重生 surface_name
  if profile.record_spawn_surface_count == nil then
    profile.record_spawn_surface_count = {}
  end
  if profile.record_spawn_surface_count[surface_name] == nil then
    profile.record_spawn_surface_count[surface_name] = 1
  end
  profile.record_spawn_surface_count[surface_name] = profile.record_spawn_surface_count[surface_name] + 1

  if player.character.surface.platform ~= nil then
    -- 将trash的前count格物品插入玩家背包
    local trash = player.surface.platform.hub.get_inventory(defines.inventory.hub_main)
    for i = 1, count do
      if trash[i].valid_for_read then
        -- 获取物品堆栈
        local stack = trash[i]
        -- 将物品插入玩家背包
        player.insert(stack)
      end
    end
  end

  tm.destroy_team(teaminfo)
  game.print(string.format("〓 星域传音 〓  恭喜 [color=#00ffff]%s[/color] 突破至 %s[gps=%d,%d,%s]", player.name, player.tag, player.position.x, player.position.y, surface_name))
end

function tm.unlock_tech_by_ascension(player)
  local profile = g_pf.player_profile(player)

  if profile.record_spawn_surface_count == nil then
    profile.record_spawn_surface_count = {}
  end

  local info = profile.record_spawn_surface_count

  local planet_techs = {
    {
      name = "nauvis",
      cap = false, -- 不启用上限
      techs = {
        { name = "mining-productivity-3", formula = function (c) return c * 2 + 3 end, msg = "采矿效率" },
        { name = "steel-plate-productivity", formula = function (c) return c + 1 end, msg = "钢板生产" }
      }
    },
    {
      name = "fulgora",
      cap = 30,
      techs = {
        { name = "processing-unit-productivity", formula = function (c) return c + 1 end, msg = "处理器生产" },
        { name = "scrap-recycling-productivity", formula = function (c) return c + 1 end, msg = "废料回收" }
      }
    },
    {
      name = "vulcanus",
      cap = 30,
      techs = {
        { name = "low-density-structure-productivity", formula = function (c) return c + 1 end, msg = "轻质结构" },
        { name = "rocket-part-productivity", formula = function (c) return c + 1 end, msg = "火箭部件" }
      }
    },
    {
      name = "gleba",
      cap = 30,
      techs = {
        { name = "rocket-fuel-productivity", formula = function (c) return c + 1 end, msg = "火箭燃料" },
        { name = "plastic-bar-productivity", formula = function (c) return c + 1 end, msg = "塑料棒" },
        { name = "asteroid-productivity", formula = function (c) return c + 1 end, msg = "小行星开采" }
      }
    }
  }

  -- 等级解锁配置表
  local index_unlocks = {
    { threshold = 1, tech = "biter-egg-handling", msg = "虫卵处理" },
    { threshold = 10, tech = "stack-inserter", msg = "堆叠机械臂" },
    { threshold = 20, tech = "inserter-capacity-bonus-5", msg = "机械臂容量Ⅴ" },
    { threshold = 30, tech = "inserter-capacity-bonus-6", msg = "机械臂容量Ⅵ" },
    { threshold = 40, tech = "inserter-capacity-bonus-7", msg = "机械臂容量Ⅶ" },
    { threshold = 50, tech = "transport-belt-capacity-1", msg = "传送带容量I" },
    { threshold = 60, tech = "transport-belt-capacity-2", msg = "传送带容量II" }
  }

  local force = player.force
  local ascension_cnt = g_pf.get_player_ascension_cnt(player)
  local common_level = math.ceil(ascension_cnt / 4) + 7

  -- 处理等级解锁技术
  for _, unlock in ipairs(index_unlocks) do
    if ascension_cnt > unlock.threshold then
      force.technologies[unlock.tech].researched = true
      game.print(string.format("境界突破：[technology=%s]已解锁", unlock.tech))
    end
  end

  -- 处理通用技术等级
  if ascension_cnt > 1 then
    local tech_groups = {
      { name = "research-productivity", level = ascension_cnt, msg = "研究效率" },
      { name = "stronger-explosives-7", level = common_level, msg = "炸药强化" },
      { name = "physical-projectile-damage-7", level = common_level, msg = "动能武器" },
      { name = "laser-weapons-damage-7", level = common_level, msg = "能量武器" },
      { name = "worker-robots-speed-7", level = common_level, msg = "无人机速度" }
    }

    local msg = { "当前境界：" .. g_pf.get_player_title(ascension_cnt) }

    for _, tech in ipairs(tech_groups) do
      force.technologies[tech.name].level = tech.level
      table.insert(msg, string.format("[technology=%s]提升至Lv%d", tech.name, tech.level))
    end
    game.print(table.concat(msg, "\n"))
  end

  -- 处理星球技术
  for _, planet in ipairs(planet_techs) do
    local cnt = info[planet.name] or 0
    if cnt > 0 then
      local count = planet.cap and math.min(cnt, planet.cap) or cnt
      local msg = { string.format("在[planet=%s]重生%d次", planet.name, cnt) }

      for _, tech in ipairs(planet.techs) do
        local level = tech.formula(count)
        force.technologies[tech.name].level = level
        table.insert(msg, string.format("[technology=%s]提升至Lv%d", tech.name, level))
      end

      game.print(table.concat(msg, "\n"))
    end
  end
end

return tm
