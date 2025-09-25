local function show_online_player_postion(player_print)
  for _, player in pairs(game.players) do
    if player.connected then
      player_print.print(string.format("[gps=%d,%d,%s] [color=#00ffff]%s[/color]%s", player.position.x,
        player.position.y,
        player.surface.name,
        player.name, player.tag))
    end
  end
end


local function insert_item(player, item_name, cnt, quality)
  if not count then count = 1 end
  if not quality then quality = "normal" end
  player.insert{ name = item_name, count = cnt, quality = quality }
  player.print("道友" .. g_utils.markup_wrap("color", "#00ffff")(player.name) .. "获得" .. g_utils.item_text(item_name, cnt, quality))
end

local function show_move_platform(player_print)
  for _, surface in pairs(game.surfaces) do
    -- if surface.platform ~= nil and surface.platform.space_location == nil then
    --     player_print.print(string.format("[gps=0,0,%s] %s", surface.name, surface.platform.name))
    -- end
    if surface.platform ~= nil then
      player_print.print(string.format("[gps=0,0,%s] %s", surface.name, surface.platform.name))
    end
  end
end


-- 矿石采集
local ore_names = { "uranium-ore", "coal", "stone", "iron-ore", "copper-ore", "tungsten-ore", "calcite", "holmium-ore", "scrap" }
local herb_names = { "yumako", "jellynut", "spoilage" }
local treasure_names = { "iron-bacteria", "copper-bacteria", "pentapod-egg", "biter-egg" }
local random_qualities = { "normal", "normal", "normal", "uncommon", }
local time_table_shichen = { "子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥" }
local time_table_shike = { "一", "二", "三", "四", "五", "六", "七", "八" }

script.on_event(defines.events.on_console_chat, function (event)
  -- 跳过命令和系统消息
  if event.message:sub(1, 1) == "/" then return end

  if not event.player_index then return end
  local player = game.get_player(event.player_index)
  if not player then return end

  local message = event.message

  if message == "神识感应" or message == "在线的人" or message == "玩家" then
    show_online_player_postion(player)
    return
  end

  if message == "观星寻舟" or message == "飞行的船" or message == "平台" then
    show_move_platform(player)
    return
  end

  if message == "钓鱼" or message == "捕鱼" then
    local count = math.random(-1, 2)
    if count > 0 then
      insert_item(player, "raw-fish")
    else
      player.print("道友 [color=#00ffff]" .. player.name .. "[/color]一无所获")
    end
    return
  end

  if message == "伐木" or message == "砍树" then
    insert_item(player, "wood")
    return
  end

  if message == "采矿" or message == "采石" or message == "挖矿" then
    insert_item(player, ore_names[math.random(#ore_names)])
    return
  end

  if message == "采药" then
    insert_item(player, herb_names[math.random(#herb_names)])
    return
  end

  if message == "捕猎" or message == "狩猎" then
    if not player.force.technologies["biter-egg-handling"].researched then
      player.force.technologies["biter-egg-handling"].researched = true
    end
    insert_item(player, treasure_names[math.random(#treasure_names)])
    return
  end

  if message == "观星" then
    local shichen = math.floor(game.tick / (120 * 60 * 60)) % 12
    local shike = math.floor(game.tick / (15 * 60 * 60)) % 8
    player.print(string.format("%s时%s刻", time_table_shichen[1 + shichen], time_table_shike[1 + shike]))
    return
  end

  -- 自定义消息格式
  local team_name = g_tm.get_team_name(player.force)
  local custom_message = string.format("[color=#ffff00]%s[/color] [color=#00ffff]%s[/color]%s 说 %s", team_name, player.name, player.tag, event.message)

  -- 广播自定义消息给所有其他门派和player
  for _, force in pairs(game.forces) do
    if force.name ~= player.force.name then
      force.print(custom_message, { color = player.color })
    end
  end

  -- 广播自定义消息给player
  if player.force.name ~= game.forces.player.name then
    game.forces.player.print(custom_message, { color = player.color })
  end

  LogI("player talk", { player = player.name, msg = event.message })
end)
