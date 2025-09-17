local tm = require("script.team_manager")

local restrict = {}

if not SwordSageDebugMod then
  function restrict.on_platform_tile_check(event)
    local platform = event.platform
    local surface = platform.surface

    local max_level = 0
    for _, player in pairs(platform.force.players) do
      local currlevel = g_pf.get_player_ascension_cnt(player)
      if currlevel > max_level then
        max_level = currlevel
      end
    end

    local weight_sum = 0
    for _, platform in pairs(platform.force.platforms) do
      weight_sum = weight_sum + platform.weight
    end

    if weight_sum > (max_level * 100 + 3000) * 1000 then
      for _, info in pairs(event.tiles) do
        surface.set_tiles({ {
          name = info.old_tile,
          position = info.position
        } })
      end
    end

    if #platform.force.platforms > max_level + 3 then
      local platform = platform.force.platforms[max_level + 4]
      if platform then
        local hub = platform.hub
        if hub then
          hub.damage(100000000, "enemy")
        end
      end
    end
  end

  -- todo : 蓝图覆盖修改他人
  -- 监听蓝图创建事件
  script.on_event(defines.events.on_player_setup_blueprint, function (event)
    local player = game.get_player(event.player_index)
    if not player then return end

    -- 获取蓝图实体
    local blueprint = player.blueprint_to_setup
    if not blueprint or not blueprint.valid_for_read then
      blueprint = player.cursor_stack
    end
    if not blueprint or not blueprint.valid_for_read then return end

    -- 获取选择的区域内的实体
    local entities = event.mapping.get()
    if not entities then return end

    -- 检查是否包含其他势力的建筑
    for _, entity in pairs(entities) do
      if entity.valid and entity.force ~= player.force then
        -- 清空蓝图
        blueprint.clear_blueprint()
        -- 提示玩家
        player.print(string.format("▣ 不能复制其他门派的建筑作为蓝图[gps=%d,%d,%s] ▣ %s", entity.position.x, entity.position.y,
          entity.surface.name, player.name))
        return
      end
    end
  end)

  -- 监听玩家旋转建筑事件
  script.on_event(defines.events.on_player_rotated_entity, function (event)
    local player = game.get_player(event.player_index)
    local entity = event.entity

    if player and entity and entity.valid then
      -- 检查是否为其他势力的建筑
      if entity.force ~= player.force then
        -- 还原旋转（向反方向旋转回去）
        if event.previous_direction then
          entity.direction = event.previous_direction
        end
        -- 提示玩家
        player.print(string.format("▣ 不能旋转其他门派的建筑[gps=%d,%d,%s] ▣ %s", entity.position.x, entity.position.y,
          entity.surface.name, player.name))
      end
    end
  end)


  -- 监听玩家打开GUI事件
  script.on_event(defines.events.on_gui_opened, function (event)
    local player = game.get_player(event.player_index)
    if not player then return end

    -- 检查打开的是否为实体GUI
    if event.gui_type == defines.gui_type.entity then
      local entity = event.entity
      -- 检查实体是否有效且不属于玩家势力
      if entity and entity.valid and entity.force ~= player.force then
        -- 关闭GUI
        player.opened = nil
        -- 提示玩家
        player.print(string.format("▣ 不能查看或修改其他门派的建筑[gps=%d,%d,%s] ▣ %s", entity.position.x, entity.position.y,
          entity.surface.name, player.name))
      end
    end
  end)

  -- 监听玩家复制实体设置事件
  script.on_event(defines.events.on_entity_settings_pasted, function (event)
    local player = game.get_player(event.player_index)
    local source = event.source           -- 复制源
    local destination = event.destination -- 粘贴目标

    if player and destination and destination.valid then
      -- 检查目标实体是否属于其他势力
      if destination.force ~= player.force then
        -- 提示玩家
        player.print(string.format("▣ 不能通过复制设置修改其他门派设施[gps=%d,%d,%s] ▣ %s", destination.position.x,
          destination.position.y,
          destination.surface.name, player.name))
        game.print(string.format("▣ %s已被杀死，大家不要学他 ▣", player.name))
        -- 杀死这样操作的玩家
        player.character.die()
      end
    end
  end)


  -- 机器人创建时调用
  script.on_event(defines.events.on_robot_built_entity, function (event)
    local entity = event.entity
    -- tm.destroy_radar(entity)

    if not tm.is_in_force_area(entity) then
      entity.destroy()
    end
  end)

  -- 创建实体时调用
  script.on_event(defines.events.on_built_entity, function (event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local entity = event.entity
    -- tm.destroy_radar(entity)

    if not tm.is_in_force_area(entity) then
      player.print("▣ 不能在此区域创建实体 ▣" .. player.name)
      entity.destroy()
    end
  end)
end

return restrict
