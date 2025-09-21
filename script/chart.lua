local chart = {}

local function chart_entity_position(entity, force, radius)
  local x = entity.position.x
  local y = entity.position.y
  local area = { { x - radius, y - radius }, { x + radius, y + radius } }
  force.chart(entity.surface, area)
end

local function get_all_connected_players_forces()
  local forces = {}
  for _, force in pairs(game.forces) do
    if (force.name ~= "player") and (#force.connected_players > 0) then
      table.insert(forces, force)
    end
  end
  return forces
end

function chart.do_chart()
  local online_forces = get_all_connected_players_forces()

  for _, force in pairs(online_forces) do
    for _, player in pairs(game.connected_players) do
      if player.force.name ~= force.name then
        chart_entity_position(player, force, 32 * 2)
      end
    end
  end
end

function chart.on_10_second(event)
  chart.do_chart()
end

return chart
