local coin_gen_rate = {
  ["small-biter"] = 0.1,
  ["medium-biter"] = 0.2,
  ["big-biter"] = 0.5,
  ["behemoth-biter"] = 1,
  ["small-spitter"] = 0.1,
  ["medium-spitter"] = 0.2,
  ["big-spitter"] = 0.5,
  ["behemoth-spitter"] = 0.5,
  ["small-worm-turret"] = 0.8,
  ["medium-worm-turret"] = 1,
  ["big-worm-turret"] = 1,
  ["behemoth-worm-turret"] = 1,
  ["biter-spawner"] = 1,
  ["spitter-spawner"] = 1,
}

local Coins = {}

function Coins.on_entity_died(event)
  local count = coin_gen_rate[event.entity.prototype.name]
  if count == nil then
    return
  end

  local drop_amount = 0
  if (count < 1) then
    local n = math.random(100)
    if (n < count * 100) then
      drop_amount = 1
    end
  elseif (count >= 1) then
    -- 修复：确保随机范围有效且结果为正数
    local min_count = math.max(1, math.floor(count * 80))          -- 至少为1
    local max_count = math.max(min_count, math.floor(count * 120)) -- 至少等于min_count
    drop_amount = math.random(min_count, max_count)
  end

  -- 添加额外的安全检查
  drop_amount = math.floor(drop_amount or 0)
  if not drop_amount or drop_amount <= 0 then
    return
  end

  local surface = game.surfaces[event.entity.surface_index]
  local pos = event.entity.position

  surface.spill_item_stack{
    position = pos,
    stack = { name = "coin", count = drop_amount },
    enable_looted = true,
    force = nil,
  }
end

return Coins
