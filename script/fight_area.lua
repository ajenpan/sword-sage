require("script.utils")
local pm = require("script.player_manager")
local uih = require("script.ui_helper")
local pf = require("script.player_profile")
local mg = require("script.map_gen")
local fight_prefix = "fight_area_"
local fight_perfix_len = #fight_prefix

local fight_area = {}
local fight_area_size = 128
local challeng_cd = 5 * TICKS_PER_SECOND

local challenge_state = {
  unready = 0,
  infight = 1,
  finished = 2,
}

function fight_area.on_init()
  if storage.fight_area_record == nil then
    storage.fight_area_record = {}
  end
end

local function create_fight_surface(player)
  local surfacename = fight_prefix .. player.force.name

  if game.surfaces[surfacename] ~= nil then
    return game.surfaces[surfacename]
  end

  local map_settings = game.default_map_gen_settings or {}
  map_settings.peaceful_mode = false
  map_settings.no_enemies_mode = false
  map_settings.seed = math.random()
  map_settings.width = fight_area_size
  map_settings.height = fight_area_size
  local surface = game.create_surface(surfacename, map_settings)
  surface.show_clouds = false
  surface.always_day = true
  -- local zero_point = { x = 0, y = 0 }
  -- local size = { x = 8, y = 8 }
  -- if not surface.is_chunk_generated(zero_point) then
  --   log("request_to_generate_chunks:" .. surfacename)
  --   surface.request_to_generate_chunks(zero_point)
  -- end
  -- local left_top, right_bottom = mg.get_bounding_box_pos(zero_point, size)
  -- mg.create_rect_pos(left_top, right_bottom, { x = 1, y = 1 }, nil, function (pos)
  --   surface.set_tiles({ {
  --     name = "refined-concrete",
  --     position = pos
  --   } })
  -- end)
  return surface
end

function fight_area.state_info(player)
  local s = storage.fight_area_state
  if s == nil then
    storage.fight_area_state = {}
    s = storage.fight_area_state
  end

  if s[player.index] == nil then
    s[player.index] = {
      state = 0,
      cd_finish_at = 0,
      config = {}
    }
  end
  return s[player.index]
end

function fight_area.record_info(player)
  local s = storage.fight_area_record
  if s == nil then
    storage.fight_area_record = {}
    s = storage.fight_area_record
  end

  if s[player.index] == nil then
    s[player.index] = {
      max_consecutive_victories = 0, -- 最大连胜
      cur_consecutive_victories = 0, -- 当前连胜, 连败为负数
      cur_floor = 1,                 --当前楼层
      config = {}
    }
  end
  return s[player.index]
end

function fight_area.create_enemies(surface, config)
  fight_area.create_biter_spwaner(surface, config)

  if config.floor > 5 then
    fight_area.create_worm_turret(surface, config)
  end

  -- Spitter spawner	
  if config.floor > 10 then
    fight_area.create_spitter_spwaner(surface, config)
  end

  -- Small egg raft
  if config.floor > 15 then
    -- gleba_spawner_small
    fight_area.create_gleba_spawner_small(surface, config)
  end

  if config.floor > 20 then
    -- gleba_spawner
    fight_area.create_gleba_spawner(surface, config)
  end

  local ex_enemis = {
    { name = "big-spitter", cnt = config.defficulty, },
    { name = "behemoth-spitter", cnt = config.defficulty / 2, },
    { name = "small-strafer-pentapod", cnt = config.defficulty / 10 },
    { name = "medium-strafer-pentapod", cnt = config.defficulty / 20 },
    { name = "big-strafer-pentapod", cnt = config.defficulty / 30 },
    { name = "small-stomper-pentapod", cnt = config.defficulty / 10 },
    { name = "medium-stomper-pentapod", cnt = config.defficulty / 20 },
    { name = "big-stomper-pentapod", cnt = config.defficulty / 30 },
    { name = "small-demolisher", cnt = config.defficulty / 10 },
    { name = "medium-demolisher", cnt = config.defficulty / 25 },
    { name = "big-demolisher", cnt = config.defficulty / 50 },
  }

  local half_size = 60
  local left_top = { x = -half_size, y = -half_size }
  local right_bottom = { x = half_size, y = half_size }
  local spacing = { x = 2, y = 2 }

  local poses = {}
  mg.create_rect_edge_pos(left_top, right_bottom, { x = 5, y = 5 }, spacing, function (pos, edge)
    poses[#poses + 1] = pos
  end)

  poses = g_utils.shuffle(poses)

  for k, v in pairs(ex_enemis) do
    for i, pos in pairs(poses) do
      if v.cnt >= 1 then
        surface.create_entity({
          name = v.name,
          position = pos,
          force = "enemy",
          quality = config.enemy_quality,
        })
        ex_enemis[k].cnt = ex_enemis[k].cnt - 1
      end

      if ex_enemis[k].cnt < 1 then
        ex_enemis[k] = nil
        break
      end
    end
  end
end

function fight_area.create_worm_turret(surface, config)
  -- medium-worm-turret
  local cnt = config.defficulty
  local worm_turret = "small-worm-turret"
  if config.floor > 15 then
    worm_turret = "behemoth-worm-turret"
  elseif config.floor > 10 then
    worm_turret = "big-worm-turret"
  elseif config.floor > 5 then
    worm_turret = "medium-worm-turret"
  end
  local half_size = 20
  mg.create_rect_edge_pos({ x = -half_size, y = -half_size }, { x = half_size, y = half_size }, { x = 2, y = 2 }, { x = 2, y = 2 }, function (pos)
    if cnt > 0 then
      cnt = cnt - 1
      surface.create_entity({
        name = worm_turret,
        position = pos,
        force = "enemy",
        quality = config.enemy_quality,
      })
    end
  end)
end

function fight_area.create_biter_spwaner(surface, config)
  local half_size = 30
  mg.create_rect_edge_pos({ x = -half_size, y = -half_size }, { x = half_size, y = half_size }, { x = 5, y = 5 }, { x = 4, y = 4 }, function (pos, edge)
    surface.create_entity({
      name = "biter-spawner",
      position = pos,
      force = "enemy",
      quality = config.enemy_quality,
    })
  end)
end

function fight_area.create_spitter_spwaner(surface, config)
  local half_size = 38
  local cnt = config.defficulty / 2
  mg.create_rect_edge_pos({ x = -half_size, y = -half_size }, { x = half_size, y = half_size }, { x = 5, y = 5 }, { x = 4, y = 4 }, function (pos, edge)
    if cnt <= 0 then
      return
    end
    cnt = cnt - 1
    surface.create_entity({
      name = "spitter-spawner",
      position = pos,
      force = "enemy",
      quality = config.enemy_quality,
    })
  end)
end

function fight_area.create_gleba_spawner_small(surface, config)
  local half_size = 45
  local cnt = config.defficulty / 5
  mg.create_rect_edge_pos({ x = -half_size, y = -half_size }, { x = half_size, y = half_size }, { x = 5, y = 5 }, { x = 4, y = 4 }, function (pos, edge)
    if cnt <= 0 then
      return
    end
    cnt = cnt - 1
    surface.create_entity({
      name = "gleba-spawner-small",
      position = pos,
      force = "enemy",
      quality = config.enemy_quality,
    })
  end)
end

function fight_area.create_gleba_spawner(surface, config)
  local half_size = 52

  local left_top = { x = -half_size, y = -half_size }
  local right_bottom = { x = half_size, y = half_size }
  local entity_size = { x = 5, y = 5 }
  local spacing = { x = 2, y = 2 }

  local cnt = config.defficulty / 10

  mg.create_rect_edge_pos(left_top, right_bottom, { x = 5, y = 5 }, spacing, function (pos, edge)
    if cnt <= 0 then
      return
    end
    cnt = cnt - 1

    local entiry = surface.create_entity({
      name = "gleba-spawner",
      position = pos,
      force = "enemy",
      quality = config.enemy_quality,
    })
  end)
end

function fight_area.create(player, config)
  if config == nil then
    config = {
      player_level = 1,
      enemy_quality = "normal"
    }
  end

  local info = fight_area.state_info(player)

  if info.state ~= challenge_state.unready then
    player.print("你已经在挑战中了")
    return false
  end

  -- cd check
  if game.tick < info.cd_finish_at then
    player.print("距离上次挑战时间太短,请稍后再试")
    return false
  end

  local record = fight_area.record_info(player)

  -- Difficulty
  local defficulty = 1.35 ^ record.cur_floor + config.player_level -- 加上转生次数的平方?
  if record.cur_consecutive_victories > 0 then
    defficulty = defficulty + record.cur_consecutive_victories
  end

  defficulty = math.floor(defficulty)

  local surface = create_fight_surface(player)
  fight_area.destroy_all_enemy(surface)

  local enemy = game.forces.enemy
  enemy.set_evolution_factor(defficulty * 0.1, surface)

  local sec = 60 + (record.cur_floor - 1) * 2
  local challenge_time = sec * TICKS_PER_SECOND

  local def_cfg = {
    quality = config.enemy_quality,
    floor = record.cur_floor,
    defficulty = defficulty,
    consecutive_victories = record.cur_consecutive_victories,
  }

  log("user tp fight area:" .. serpent.line(player) .. serpent.line(def_cfg))

  game.print(string.format("道友:%s 进入第%s层镇妖塔,难度:%s,让我们来围观他的表现!!! [gps=0,0,%s]", player.name, record.cur_floor, defficulty, surface.name))
  player.print(string.format("消灭全部敌人或者存活 %s 秒", g_utils.markup_wrap("color", g_utils.colors_hex.red)(sec)))

  fight_area.create_enemies(surface, def_cfg)

  info.last_chanllenge_at = game.tick
  info.player_index = player.index
  info.fight_surface_index = surface.index
  info.start_tick = game.tick
  info.expect_end_tick = game.tick + challenge_time
  info.player_from = player.position
  info.player_from.surface_name = player.surface.name

  fight_area.teleport_player(player, surface)

  info.state = challenge_state.infight
  g_ptp.set_teleport_enabled(player, false)

  -- attack
  surface.set_multi_command{
    command = { type = defines.command.go_to_location, destination = { x = 0, y = 0 }, radius = 10, distraction = defines.distraction.by_enemy },
    unit_count = 99999,                         -- 想要命令的单位数量上限
    force = game.forces.enemy,                  -- 哪个 force 的单位
    unit_search_distance = fight_area_size * 2, -- 搜索范围（tile）
  }
  return true
end

function fight_area.is_fight_surface(surface)
  local name = surface.name
  return (#name > fight_perfix_len and string.sub(name, 1, fight_perfix_len) == fight_prefix)
end

function fight_area.teleport_player(player, surface)
  if surface == nil then
    player.print("surface is nil")
    return
  end

  if player.character == nil then
    player.print("character is nil")
    return
  end

  if player.character.surface.platform ~= nil then
    player.print("太空中无法传送")
    return
  end

  local spawn_position = player.force.get_spawn_position(surface)

  player.print(player.name .. player.tag .. "传送到[gps=" .. spawn_position.x .. "," .. spawn_position.y .. "," .. surface.name .. "]")

  if player.vehicle then
    player.vehicle.teleport(spawn_position, surface)
  else
    player.teleport(spawn_position, surface)
  end
end

function fight_area.on_challenge_fight(player, info)
  if game.tick - info.start_tick < 2 * 60 then
    -- do nothing
    return
  end
  local surface = game.surfaces[info.fight_surface_index]
  if player == nil or not player.valid or surface == nil then
    fight_area.do_challenge_finished(player, info)
    return
  end

  -- if player.character == nil or not player.character.valid then
  --   fight_area.do_challenge_finished(player, info)
  --   return
  -- end

  if game.tick >= info.expect_end_tick then
    fight_area.do_challenge_finished(player, info, true)
    return
  end

  -- check enemy count
  local enemies = player.surface.count_entities_filtered({ force = "enemy" })

  if enemies <= 0 then
    fight_area.do_challenge_finished(player, info, true)
    return
  end

  local left_seconds = math.floor((info.expect_end_tick - game.tick) / TICKS_PER_SECOND)

  if left_seconds < 10 then
    player.print("挑战剩余时间:" .. left_seconds .. "秒;" .. "剩余敌人数量:" .. enemies)
  end
end

function fight_area.destroy_all_enemy(fight_surface)
  if not (fight_surface and fight_surface.valid) then return end
  local entities = fight_surface.find_entities_filtered({ force = { "enemy" } })
  if entities ~= nil then
    for _, entity in pairs(entities) do
      if entity.valid then
        entity.destroy()
      end
    end
  end
end

function fight_area.do_challenge_finished(player, info, success)
  info.state = challenge_state.finished

  info.real_finsished_at = game.tick
  info.clear_at = game.tick + 3 * TICKS_PER_SECOND

  fight_area.destroy_all_enemy(game.surfaces[info.fight_surface_index])

  local str = success and "成功" or "失败"
  local from_surface = info.player_from.surface_name
  local from_pos = info.player_from

  local notifystr = string.format("道友 [color=#00ffff]%s[/color] 挑战%s,3秒后传送回原地[gps=%d,%d,%s]", player.name, str, from_pos.x, from_pos.y, from_surface)
  player.print(notifystr)

  -- record
  local record = fight_area.record_info(player)
  if success then
    if record.cur_consecutive_victories >= 0 then
      -- 连胜
      record.cur_consecutive_victories = record.cur_consecutive_victories + 1
    else
      record.cur_consecutive_victories = 1
    end
  else
    -- 如果失败:
    if record.cur_consecutive_victories >= 0 then
      record.cur_consecutive_victories = -1
    else
      -- 连败
      record.cur_consecutive_victories = record.cur_consecutive_victories - 1
    end
  end
  if record.cur_consecutive_victories > record.max_consecutive_victories then
    record.max_consecutive_victories = record.cur_consecutive_victories
  end

  if success then
    record.cur_floor = record.cur_floor + 1
  end
end

function fight_area.on_player_died(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  local is_in_fight_area = fight_area.is_fight_surface(player.surface)
  if not is_in_fight_area then
    return
  end
  local info = fight_area.state_info(player)
  if info and info.state == challenge_state.infight then
    fight_area.do_challenge_finished(player, info, false)
  end
end

function fight_area.on_second(event)
  local s = storage.fight_area_state
  if s == nil then
    return
  end
  for player_index, info in pairs(s) do
    local player = game.players[player_index]

    if info.state == challenge_state.infight and info.fight_surface_index ~= player.surface.index then
      game.print("发现玩家意外离开了挑战,当前位于:" .. player.surface.name)
      game.print("强制结束挑战")
      fight_area.do_challenge_finished(player, info, false)
      goto continue
    end

    if info.state == challenge_state.infight then
      fight_area.on_challenge_fight(player, info)
    elseif info.state == challenge_state.finished then
      fight_area.on_challenge_finished(player, info)
    elseif info.state == challenge_state.unready then
      -- fight_area.on_challenge_unready(player, info)
    end

    ::continue::
  end
end

function fight_area.on_challenge_finished(player, info)
  if not (info.clear_at) or (game.tick > info.clear_at) then
    local from_pos = info.player_from
    if player.vehicle then
      player.vehicle.teleport(from_pos, from_pos.surface_name)
    else
      player.teleport(from_pos, from_pos.surface_name)
    end
    fight_area.do_challenge_unready(player, info)
    g_ptp.set_teleport_enabled(player, nil)
  end
end

function fight_area.do_challenge_unready(player, info)
  info.state = challenge_state.unready
  info.cd_finish_at = game.tick + challeng_cd
end

function fight_area.create_gui_pane(frame, player)
  g_uih.add(frame, { type = "label", caption = "慎入, 死亡丢失背包" })

  g_uih.add(frame, { type = "line" })
  local flow = frame.add{ type = "flow", name = "quality_flow", direction = "horizontal" }
  flow.add{ type = "label", caption = "敌人品质:" }

  local qualities = { "normal", "uncommon", "rare", "epic", "legendary" }
  for _, q in ipairs(qualities) do
    -- flow.add
    uih.add(flow, {
      type = "sprite-button",
      name = "fight_area.quality_btn_" .. q,
      style = "slot_button",
      sprite = "quality-" .. q,
      toggled = (q == "normal"),
      on_click = function (event)
        local element = event.element
        if not (element and element.valid) then return end
        local player = game.get_player(event.player_index)
        local parent = element.parent
        for _, child in pairs(parent.children) do
          if child.type == "sprite-button" then
            child.toggled = false
          end
        end
        fight_area.record_info(player).config.enemy_quality = q
        element.toggled = true
      end
    })
  end

  uih.add(flow, {
    name = "fight_area.btn_start_challenge",
    type = "button",
    caption = "开始挑战",
    style = "confirm_button_without_tooltip",
    on_click = function (event)
      local player = game.get_player(event.player_index)
      if not (player and player.character) then return end

      if player.hub ~= nil then
        player.print("太空中无法传送")
        return
      end
      if player.cargo_pod ~= nil then
        player.print("飞船中无法传送")
        return
      end
      if player.character.surface.platform ~= nil then
        player.print("太空中无法传送")
        return
      end
      g_ui.set_main_frame_visible(player, false)
      local config = fight_area.record_info(player).config
      config.player_level = pf.get_player_level(player)
      fight_area.create(player, config)
    end
  })

  g_uih.add(frame, { type = "line" })
  g_uih.add(frame, { type = "label", caption = "镇妖塔排行榜:" })

  -- rank
  local rank = {}
  if not storage.fight_area_record then
    storage.fight_area_record = {}
  end
  for k, record in pairs(storage.fight_area_record) do
    local p = game.players[k]
    if p then
      rank[#rank + 1] = {
        player_name = p.name,
        cur_floor = record.cur_floor,
        max_consecutive_victories = record.max_consecutive_victories
      }
    end
  end

  table.sort(rank, function (a, b)
    if a.cur_floor == b.cur_floor then
      return a.max_consecutive_victories > b.max_consecutive_victories
    end
    return a.cur_floor > b.cur_floor
  end
  )

  local tab = g_uih.add(frame, { type = "table", column_count = 4, horizontal_scroll_policy = "never", vertical_scroll_policy = "auto-and-reserve-space" })

  tab.add{ type = "label", caption = "排名" }.style.width = 40
  tab.add{ type = "label", caption = "称呼" }.style.width = 100
  tab.add{ type = "label", caption = "层数" }.style.width = 100
  tab.add{ type = "label", caption = "最高连胜" }.style.width = 100

  for i, info in ipairs(rank) do
    g_uih.add(tab, { type = "label", caption = "   " .. i, style_table = { width = 40 } })
    g_uih.add(tab, { type = "label", caption = info.player_name, style_table = { width = 100 } })
    g_uih.add(tab, { type = "label", caption = info.cur_floor - 1, style_table = { width = 100 } })
    g_uih.add(tab, { type = "label", caption = info.max_consecutive_victories, style_table = { width = 100 } })
  end
end

return fight_area
