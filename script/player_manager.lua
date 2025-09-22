local pm = {}


function pm.on_init()

end

function pm.has_team(player)
  return (player.force.name ~= "player")
end

function pm.on_player_joined_game(event)
  local player = game.players[event.player_index]
  if not (player) then return end
  -- update player title
  player.tag = g_pf.get_player_title(g_pf.get_player_ascension_cnt(player))
  local playername = g_utils.markup_wrap("color", "#00ffff")(player.name)
  if player.online_time > 0 then
    local last_delta = math.max(0, math.floor((game.tick - player.last_online) / TICKS_PER_HOUR))
    local total_time = math.max(0, math.floor(player.online_time / TICKS_PER_HOUR))
    game.print(string.format("欢迎道友 %s %s 重临星域！\n修仙时长 %i 小时\n已经闭关 %i 小时", player.tag, playername, total_time, last_delta))
  else
    game.print(string.format("欢迎道友 %s 光临星域", playername))
    player.print("▶点击左上角[color=#F72121]剑标[/color]打开面板查看指南")
  end

  -- update ap effect
  g_pf.update_ap_effect(player)
end

function pm.on_player_join_team(event)
  local player = game.players[event.player_index]

  if not (player) then return end

  local surfacename = player.surface.name

  -- 设置角色属性
  -- 就不送了, 送 ap 点是不是比较好
  local ascension_cnt = g_pf.get_player_ascension_cnt(player)
  -- player.character_crafting_speed_modifier = modifier
  -- player.character_mining_speed_modifier = modifier
  player.insert({ name = "vehicle-machine-gun", count = 1 })

  player.insert({ name = "wood", count = 100 })
  player.insert({ name = "iron-plate", count = 200 })
  player.insert({ name = "copper-plate", count = 200 })
  player.insert({ name = "steel-plate", count = 200 })
  player.insert({ name = "electronic-circuit", count = 200 })
  player.insert({ name = "iron-gear-wheel", count = 200 })
  player.insert({ name = "steel-furnace", count = 50 })
  player.insert({ name = "pipe", count = 200 })
  player.insert({ name = "substation", count = 20 })
  player.insert({ name = "fast-inserter", count = 50 })
  player.insert({ name = "assembling-machine-3", count = 50 })
  player.insert({ name = "electric-mining-drill", count = 50 })
  player.insert({ name = "automation-science-pack", count = 400 })
  player.insert({ name = "logistic-science-pack", count = 200 })
  player.insert({ name = "construction-robot", count = 50, quality = "legendary" })
  player.insert({ name = "solar-panel", count = 10, quality = "legendary" })
  player.insert({ name = "accumulator", count = 10, quality = "legendary" })

  if surfacename ~= "nauvis" then
    player.insert({ name = "steam-turbine", count = 20 })
    if surfacename == "vulcanus" then
      player.insert({ name = "foundry", count = 1 })
      player.insert({ name = "big-mining-drill", count = 1 })
      player.insert({ name = "refined-concrete", count = 200 })
    elseif surfacename == "fulgora" then

    elseif surfacename == "gleba" then
      player.insert({ name = "spoilage", count = 200 }) -- 变质物
      player.insert({ name = "biochamber", count = 1 }) -- 生物工厂
    end
  end

  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  if armor_inv and (armor_inv.is_empty() or not armor_inv[1].valid_for_read) then
    -- local quality = "normal"
    -- player.insert{ name = "mech-armor", count = 1, quality = quality }
    -- player.insert{ name = "modular-armor", count = 1 }

    player.insert{ name = "power-armor-mk2", count = 1 }
    local quality = "legendary"
    player.insert{ name = "personal-roboport-equipment", count = 1, quality = quality }
    player.insert{ name = "solar-panel-equipment", count = 2, quality = quality }
    player.insert{ name = "battery-mk3-equipment", count = 1, quality = quality }

    armor_inv = player.get_inventory(defines.inventory.character_armor)
    if armor_inv == nil then
      return
    end
    local p_armor = armor_inv[1].grid
    if p_armor == nil then
      player.print("无法获取装备栏，请检查")
      return
    end
    -- p_armor.put({ name = "fusion-reactor-equipment", quality = quality })
    -- p_armor.put({ name = "exoskeleton-equipment", quality = quality })
    -- p_armor.put({ name = "exoskeleton-equipment", quality = quality })
    -- p_armor.put({ name = "exoskeleton-equipment", quality = quality })
    -- p_armor.put({ name = "exoskeleton-equipment", quality = quality })
    -- p_armor.put({ name = "energy-shield-mk2-equipment", quality = quality })
    -- p_armor.put({ name = "personal-roboport-mk2-equipment", quality = quality })
    -- p_armor.put({ name = "night-vision-equipment", quality = quality })
    -- p_armor.put({ name = "battery-mk2-equipment", quality = quality })
    -- p_armor.put({ name = "battery-mk2-equipment", quality = quality })
    -- p_armor.put({ name = "personal-laser-defense-equipment", quality = quality })
    -- p_armor.put({ name = "personal-laser-defense-equipment", quality = quality })
    -- p_armor.put({ name = "discharge-defense-equipment", quality = quality })
    -- p_armor.put({ name = "energy-shield-mk2-equipment", quality = quality })
    -- p_armor.put({ name = "discharge-defense-equipment", quality = quality })
    -- player.insert{ name = "railgun", count = 1, quality = quality }
    -- player.insert{ name = "railgun-ammo", count = 100, quality = quality }
  end
end

function pm.remove_offline_players()
  -- TODO:
  -- 清理 没有门派的玩家
  -- 重构 玩家最大离线时长控制
  for _, player in pairs(game.players) do
    if not player.connected then
      local index = g_pf.get_player_ascension_cnt(player)
      local last_shijian = (index * 24 + 24) * 60 * 60 * 60
      if player.last_online < game.tick - last_shijian then
        game.print("道友 [color=#00ffff]" .. player.name .. "[/color]寿元耗尽")
        game.remove_offline_players({ player })
      end
    end
  end
end

function pm.on_minute(event)
  pm.remove_offline_players()
end

function pm.on_player_left_game(event)
  local player = game.players[event.player_index]
  if not (player and player.character) then return end
  g_ui.set_main_frame_visible(player, false)
  -- game.print(string.format("[color=#ffff00]%s[/color] [color=#00ffff]%s[/color]%s 开始闭关修炼",
  --   tm.get_force_name(player.force), player.name, player.tag))
end

return pm
