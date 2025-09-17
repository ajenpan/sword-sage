local coin_gen_rate = {
  ["small-biter"] = 0.1,
  ["medium-biter"] = 0.2,
  ["big-biter"] = 0.5,
  ["behemoth-biter"] = 1,
  ["small-spitter"] = 0.1,
  ["medium-spitter"] = 0.2,
  ["big-spitter"] = 0.5,
  ["behemoth-spitter"] = 1,
  ["small-worm-turret"] = 5,
  ["medium-worm-turret"] = 10,
  ["big-worm-turret"] = 15,
  ["behemoth-worm-turret"] = 25,
  ["biter-spawner"] = 20,
  ["spitter-spawner"] = 20,
}

local Coins = {}

function Coins.on_entity_died(event)
  local count = coin_gen_rate[event.entity.prototype.name]
  if count == nil then
    -- Coins.drop_coins(event.entity.surface_index, event.entity.position, coin_generation_entry)
    return
  end


  local drop_amount = 0
  if (count < 1) then
    local n = math.random(100)
    if (n < count * 100) then
      drop_amount = 1
    end
  elseif (count >= 1) then
    drop_amount = count
    drop_amount = math.random(math.floor(count * 80), math.floor(count * 120)) / 100
  end

  -- 这里准备加上玩家幸运, 考虑是看看是小概率翻倍还是 大概率加一点

  if drop_amount <= 0 then return end

  local surface = game.surfaces[event.entity.surface_index]
  local pos = event.entity.position

  -- game.print("掉落金币:" .. math.floor(drop_amount) .. "个" .. "位置:(" .. math.floor(pos.x) .. "," .. math.floor(pos.y) .. ")")

  -- if storage.ocfg.coin_generation.auto_decon_coins then
  -- game.surfaces[surface_index].spill_item_stack {
  --   position = pos,
  --   stack = { name = "coin", count = math.floor(drop_amount) },
  --   enable_looted = true,
  --   force = force,
  --   -- allow_belts?=false,
  --   -- max_radius?=…,
  --   -- use_start_position_on_failure?=false
  -- }
  -- else

  surface.spill_item_stack{
    position = pos,
    stack = { name = "coin", count = math.floor(drop_amount) },
    enable_looted = true,
    force = nil,
    -- allow_belts?=false,
    -- max_radius?=…,
    -- use_start_position_on_failure?=false
  }
  -- end
end

return Coins
