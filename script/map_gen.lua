-- 输入 index（>=0），返回 {x, y}, ring
local function spiral_coord(index)
  if index == 0 then
    return { x = 0, y = 0 }, 0
  end

  -- 计算所在圈 r（正整数）
  local r = math.ceil((math.sqrt(index + 1) - 1) / 2)
  local start_index = (2 * r - 1) ^ 2 -- 本圈起始 index（S_r）
  local k = index - start_index       -- 本圈内的 0-based 偏移

  local A = r + 1                     -- 底边从 (0,-r) 向左到 (-r,-r) 的点数量
  local B = 2 * r                     -- 左边向上
  local C = 2 * r                     -- 顶边向右
  local D = 2 * r                     -- 右边向下

  local x, y
  if k < A then
    -- 底边，从 (0,-r) 向左
    x = -k
    y = -r
  elseif k < A + B then
    -- 左边，从 (-r,-r+1) 向上
    local k2 = k - A
    x = -r
    y = -r + (k2 + 1)
  elseif k < A + B + C then
    -- 顶边，从 (-r+1,r) 向右
    local k3 = k - (A + B)
    x = -r + (k3 + 1)
    y = r
  elseif k < A + B + C + D then
    -- 右边，从 (r,r-1) 向下
    local k4 = k - (A + B + C)
    x = r
    y = r - (k4 + 1)
  else
    -- 底边剩下部分，从 (r-1,-r) 向左到 (1,-r)
    local k5 = k - (A + B + C + D)
    x = r - (k5 + 1)
    y = -r
  end
  return { x = x, y = y }, r
end

local function add_pos(pos, v)
  if type(v) == "number" then
    return { x = pos.x + v, y = pos.y + v }
  elseif type(v) == "table" then
    return { x = pos.x + v.x, y = pos.y + v.y }
  end
  -- error
end

local function mul_pos(pos, v)
  if type(v) == "number" then
    return { x = pos.x * v, y = pos.y * v }
  elseif type(v) == "table" then
    return { x = pos.x * v.x, y = pos.y * v.y }
  end
  -- error
end

local function get_bounding_box_pos(center, size)
  local half_w = math.ceil(size.x / 2)
  local half_h = math.ceil(size.y / 2)
  local left_top = { x = center.x - half_w, y = center.y - half_h }
  local right_bottom = { x = left_top.x + size.x, y = left_top.y + size.y }
  return left_top, right_bottom
end

local function is_in_boundingbox(pos, left_top, right_bottom)
  return (pos.x >= left_top.x and pos.x < right_bottom.x)
      and (pos.y >= left_top.y and pos.y < right_bottom.y)
end

local function compute_count(range, size, spacing)
  local count = math.floor((range + spacing) / (size + spacing))
  local used = size * count + spacing * (count - 1)
  local prefix = (range - used) / 2
  return count, prefix
end

local function get_chunk_pos(left_top, right_bottom)
  local chunk_x = math.ceil((right_bottom.x - left_top.x) / 32)
  local chunk_y = math.ceil((right_bottom.y - left_top.y) / 32)
  local start_chunk = mul_pos(left_top, 1 / 32)
  local ret = {}
  for x = 0, chunk_x - 1 do
    for y = 0, chunk_y - 1 do
      ret[#ret + 1] = { x = math.floor(start_chunk.x + x), y = math.floor(start_chunk.y + y) }
    end
  end
  return ret
end

local function bounding_boxes_intersect(a, b)
  return not (
    a.right_bottom.x <= b.left_top.x or -- A 在 B 左边
    a.left_top.x >= b.right_bottom.x or -- A 在 B 右边
    a.right_bottom.y <= b.left_top.y or -- A 在 B 上方
    a.left_top.y >= b.right_bottom.y    -- A 在 B 下方
  )
end

local function get_bounding_box_center(left_top, right_bottom)
  local x = (left_top.x + right_bottom.x) / 2
  local y = (left_top.y + right_bottom.y) / 2
  return { x = x, y = y }
end

local max_team_area_size = { x = 32 * 6, y = 32 * 6 } -- include out-of-map tite
local vaild_team_area = { x = 32 * 4, y = 32 * 4 }

local mg = {}

mg.add_pos = add_pos
mg.mul_pos = mul_pos
mg.get_bounding_box_pos = get_bounding_box_pos
mg.is_in_boundingbox = is_in_boundingbox
mg.get_chunk_pos = get_chunk_pos
mg.bounding_boxes_intersect = bounding_boxes_intersect
mg.get_bounding_box_center = get_bounding_box_center
mg.max_team_area_size = max_team_area_size
mg.vaild_team_area = vaild_team_area

function mg.on_second(event)
  if (storage.map_gen_init ~= nil) then
    LogD("on map_gen_init", storage.map_gen_init)
    local step = storage.map_gen_init.step
    if step == 1 then
      storage.map_gen_init.step = step + 1

      for _, planet in pairs(game.planets) do
        local surface = planet.surface
        if surface == nil then
          surface = planet.create_surface()
          game.forces.player.set_spawn_position({ x = 2, y = 2 }, surface)
        end
        local setting = table.deepcopy(planet.surface.map_gen_settings)
        -- 因为 force 数量最多64. 所以最多只有 5 圈
        setting.width = max_team_area_size.x * 5 * 2
        setting.height = max_team_area_size.y * 5 * 2
        setting.cliff_settings = nil
        surface.map_gen_settings = setting
        surface.peaceful_mode = true
        surface.no_enemies_mode = true
        surface.always_day = true
        -- LogI("map_gen_settings:", { setting = surface.map_gen_settings, name = planet.name })
      end
    elseif step == 2 then
      if (mg.is_team_area_chunk_generated({ x = 0, y = 0 })) then
        storage.map_gen_init.step = step + 1
      end
    elseif step == 3 then
      local left_top = mul_pos(max_team_area_size, -1 / 2)
      local right_bottom = mul_pos(max_team_area_size, 1 / 2)
      local vaild_area_left_top = { x = -16, y = -16 }
      local vaild_area_right_bottom = { x = 16, y = 16 }

      for _, planet in pairs(game.planets) do
        mg.create_rect_pos(left_top, right_bottom, { x = 1, y = 1 }, { x = 0, y = 0 }, function (pos)
          local is_vail_area = is_in_boundingbox(pos, vaild_area_left_top, vaild_area_right_bottom)
          local tile_name = "out-of-map"
          if is_vail_area then
            tile_name = "refined-concrete"
          end
          planet.surface.set_tiles({ { name = tile_name, position = pos } })
        end)
        storage.map_gen_init.step = step + 1
      end

      local entities = game.planets.fulgora.surface.find_entities_filtered{ area = { { -1, -1 }, { 1, 1 } }, name = "fulgoran-ruin-attractor" }
      if entities then
        for i, v in pairs(entities) do
          v.rotatable = false
          v.operable = false
          v.destructible = false
          v.minable = false
        end
      end
    elseif step == 4 then
      storage.map_gen_init = nil
    else
      storage.map_gen_init = nil
    end
  end
end

function mg.on_init()
  storage.map_gen_init = { step = 1 }
end

function mg.create_rect_pos(left_top, right_bottom, entity_size, spacing, fn)
  if not fn then return end
  if not entity_size then entity_size = { x = 1, y = 1 } end
  if not spacing then spacing = { x = 0, y = 0 } end
  if type(spacing) == "number" then spacing = { x = spacing, y = spacing } end


  local count_x, prefix_x = compute_count((right_bottom.x - left_top.x), entity_size.x, spacing.x)
  if (count_x <= 0) then return end
  local count_y, prefix_y = compute_count((right_bottom.y - left_top.y), entity_size.y, spacing.y)
  if (count_y <= 0) then return end

  local half_w = entity_size.x / 2
  local half_h = entity_size.y / 2
  local cnt = 0

  for i = 0, count_x - 1 do
    for j = 0, count_y - 1 do
      cnt = cnt + 1
      local cx = math.floor(left_top.x + prefix_x + half_w + i * (entity_size.x + spacing.x))
      local cy = math.floor(left_top.y + prefix_y + half_h + j * (entity_size.y + spacing.y))

      fn({ x = cx, y = cy })
    end
  end
  return cnt
end

function mg.create_rect_edge_pos(left_top, right_bottom, entity_size, spacing, fn)
  if not fn then return end
  if not entity_size then entity_size = { x = 1, y = 1 } end
  if not spacing then spacing = { x = 0, y = 0 } end
  if type(spacing) == "number" then spacing = { x = spacing, y = spacing } end

  local count_x, prefix_x = compute_count((right_bottom.x - left_top.x), entity_size.x, spacing.x)
  if (count_x <= 0) then return end
  local valid_height = (right_bottom.y - left_top.y) - 2 * (entity_size.y + spacing.y)
  if (valid_height < 0) then return end
  local count_y, prefix_y = compute_count(valid_height, entity_size.y, spacing.y)

  local half_w = entity_size.x / 2
  local half_h = entity_size.y / 2

  local y_top = math.floor(left_top.y + prefix_y + half_h)
  local y_bottom = math.floor(right_bottom.y - prefix_y - half_h)
  local x_left = math.floor(left_top.x + prefix_x + half_w)
  local x_right = math.floor(right_bottom.x - prefix_x - half_w)

  local cnt = 0
  for i = 0, count_x - 1 do
    local cx = math.floor(left_top.x + prefix_x + half_w + i * (entity_size.x + spacing.x))
    fn({ x = cx, y = y_top }, "top")
    fn({ x = cx, y = y_bottom }, "bottom")
    cnt = cnt + 2
  end
  for i = 0, count_y - 1 do
    local cy = math.floor(left_top.y + prefix_y + half_h + (i + 1) * (entity_size.y + spacing.y))
    fn({ x = x_left, y = cy }, "left")
    fn({ x = x_right, y = cy }, "right")
    cnt = cnt + 2
  end
  return cnt
end

function mg.get_team_area_pos(team_index)
  local pos, ring = spiral_coord(team_index)
  pos.x, pos.y = pos.x * max_team_area_size.x, pos.y * max_team_area_size.y
  local left_top, right_bottom = get_bounding_box_pos(pos, vaild_team_area)
  return pos, left_top, right_bottom
end

function mg.is_area_chunk_generated(surface, left_top, right_bottom)
  for x = left_top.x, right_bottom.x, 32 do
    for y = left_top.y, right_bottom.y, 32 do
      if not surface.is_chunk_generated({ x = math.floor(x / 32), y = math.floor(y / 32) }) then
        return false
      end
    end
  end
  return true
end

function mg.is_team_area_chunk_generated(pos)
  local left_top, right_bottom = get_bounding_box_pos(pos, max_team_area_size)
  local chunk_pos = get_chunk_pos(left_top, right_bottom)
  local ret = true
  for _, planet in pairs(game.planets) do
    for i, chunkpos in pairs(chunk_pos) do
      local is_generated = planet.surface.is_chunk_generated(chunkpos)
      if not is_generated then
        game.forces.player.chart(planet.surface, { left_top = mul_pos(chunkpos, 32), right_bottom = mul_pos(add_pos(chunkpos, 1), 32) })
        ret = false
      end
    end
  end
  return ret
end

function mg.create_team_area(force, pos)
  local half_width = math.floor(max_team_area_size.x / 2)
  local half_height = math.floor(max_team_area_size.y / 2)
  local left_top = { x = pos.x - half_width, y = pos.y - half_height }
  local right_bottom = { x = left_top.x + max_team_area_size.x, y = left_top.y + max_team_area_size.y }

  -- destroy entity
  for _, planet in pairs(game.planets) do
    local entities = planet.surface.find_entities({ left_top = left_top, right_bottom = right_bottom })
    if entities then
      for k, v in pairs(entities) do v.destroy() end
    end
  end

  mg.create_team_nauvis_area(force, pos, left_top, right_bottom)
  mg.create_team_vulcanus_area(force, pos, left_top, right_bottom)
  mg.create_team_fulgora_area(force, pos, left_top, right_bottom)
  mg.create_team_gleba_area(force, pos, left_top, right_bottom)
  mg.create_team_aquilo_area(force, pos, left_top, right_bottom)

  -- 删除中心位置,避免卡住玩家
  for _, planet in pairs(game.planets) do
    local entities = planet.surface.find_entities({ left_top = add_pos(pos, { x = -1, y = -1 }), right_bottom = add_pos(pos, { x = 1, y = 1 }) })
    for _, e in pairs(entities) do
      if e.valid and e.type ~= "resource" then
        e.destroy()
      end
    end
  end
end

function mg.destroy_team_area(pos)
  -- local need_destory_surfaces = { "nauvis", "fulgora", "vulcanus", "gleba", "aquilo" }
  -- local left_top, right_bottom = get_bounding_box_pos(pos, max_team_area_size)
  -- local chunkpos = get_chunk_pos(left_top, right_bottom)
  -- for _, surface_name in pairs(need_destory_surfaces) do
  --   for i, v in pairs(chunkpos) do
  --     LogI("destroy_team_area delete_chunk:", i, v, left_top, right_bottom)
  --   end
  -- end
end

local function create_ore_area(surface, ore_2d, ore_area_size, resource_left_top, resource_amount_map, ore_entity_size)
  if not ore_area_size then ore_area_size = { x = 32, y = 32 } end
  if not resource_amount_map then resource_amount_map = {} end
  if not ore_entity_size then ore_entity_size = {} end

  for y, ore_y in ipairs(ore_2d) do
    for x, ore in ipairs(ore_y) do
      local amount = resource_amount_map[ore] ~= nil and resource_amount_map[ore] or 300000000
      local entity_size = ore_entity_size[ore]
      local createfn = function (pos)
        surface.create_entity({ name = ore, position = pos, amount = amount, snap_to_grid = true })
      end
      local left_top_fix = mul_pos(ore_area_size, { x = x - 1, y = y - 1 })
      local left_top = add_pos(resource_left_top, left_top_fix)
      local right_bottom = add_pos(left_top, ore_area_size)
      mg.create_rect_pos(left_top, right_bottom, entity_size, { x = 0, y = 0 }, createfn)
    end
  end
end

-- 新地星
function mg.create_team_nauvis_area(force, center_pos, left_top, right_bottom)
  local surface = game.surfaces.nauvis
  local vaild_area_left_top, vaild_area_right_bottom = get_bounding_box_pos(center_pos, vaild_team_area)

  mg.create_rect_pos(left_top, right_bottom, { x = 1, y = 1 }, { x = 0, y = 0 }, function (pos)
    local is_vail_area = is_in_boundingbox(pos, vaild_area_left_top, vaild_area_right_bottom)
    local tile_name = "out-of-map"
    if is_vail_area then
      tile_name = "grass-1"
    end
    surface.set_tiles({ { name = tile_name, position = pos } })
  end)

  -- create water
  mg.create_rect_edge_pos(vaild_area_left_top, vaild_area_right_bottom, { x = 1, y = 1 }, { x = 0, y = 0 }, function (pos)
    surface.set_tiles({ { name = "water", position = pos, } })
  end)

  -- create resource
  local resource_amount_map = {}
  local ore_entity_size = { ["crude-oil"] = { x = 3, y = 4 } }

  local resource_left_top = { x = center_pos.x - 32, y = center_pos.y - 32 }
  create_ore_area(surface, { { "coal", "stone" }, { "iron-ore", "copper-ore" }, }, { x = 32, y = 32 }, resource_left_top, resource_amount_map, ore_entity_size)

  resource_left_top = { x = resource_left_top.x, y = resource_left_top.y + 64 }
  create_ore_area(surface, { { "uranium-ore", "crude-oil" } }, { x = 32, y = 16 }, resource_left_top, resource_amount_map, ore_entity_size)

  -- create rock
  local rock_left_top = { x = center_pos.x - 32, y = center_pos.y - 2 }
  local rock_right_bottom = { x = center_pos.x + 32, y = center_pos.y + 2 }
  mg.create_rect_pos(rock_left_top, rock_right_bottom, { x = 4, y = 4 }, { x = 1, y = 1 }, function (pos)
    surface.create_entity{ name = "huge-rock", position = pos, snap_to_grid = true }
  end)

  -- create plants
  local plants_left_top = { x = center_pos.x - 1, y = center_pos.y - 32 }
  local plants_right_bottom = { x = center_pos.x + 2, y = center_pos.y + 32 }
  local plants = { "tree-01", "tree-02", "tree-02-red", "tree-03", "tree-04", "tree-05", "tree-06", "tree-06-brown", "tree-07", "tree-08", "tree-08-brown", "tree-08-red", "tree-09", "tree-09-brown", "tree-09-red", }
  mg.create_rect_pos(plants_left_top, plants_right_bottom, { x = 1, y = 1 }, { x = 1, y = 1 }, function (pos)
    surface.create_entity{ name = plants[math.random(#plants)], position = pos }
  end)

  mg.create_rect_edge_pos(vaild_area_left_top, vaild_area_right_bottom, { x = 5, y = 5 }, 2, function (pos, edge)
    if edge == "top" then
      surface.create_entity({ name = "biter-spawner", position = pos, force = force, snap_to_grid = true })
    end
  end)
end

-- 祝融星
function mg.create_team_vulcanus_area(force, center_pos, left_top, right_bottom)
  local surface = game.surfaces.vulcanus
  local vaild_area_left_top, vaild_area_right_bottom = get_bounding_box_pos(center_pos, vaild_team_area)

  mg.create_rect_pos(left_top, right_bottom, { x = 1, y = 1 }, { x = 0, y = 0 }, function (pos)
    local is_vail_area = is_in_boundingbox(pos, vaild_area_left_top, vaild_area_right_bottom)
    local tile_name = "out-of-map"
    if is_vail_area then
      tile_name = "volcanic-smooth-stone"
    end
    surface.set_tiles({ { name = tile_name, position = pos } })
  end)

  -- create lava
  mg.create_rect_edge_pos(vaild_area_left_top, vaild_area_right_bottom, { x = 1, y = 1 }, 0, function (pos)
    surface.set_tiles({ { name = "lava", position = pos, } })
  end)

  local resource_amount_map = {}
  local ore_entity_size = { ["sulfuric-acid-geyser"] = { x = 3, y = 4 } }

  local resource_left_top = { x = center_pos.x - 32, y = center_pos.y - 32 }
  create_ore_area(surface, { { "tungsten-ore", "calcite" }, }, { x = 32, y = 32 }, resource_left_top, resource_amount_map, ore_entity_size)
  create_ore_area(surface, { { "coal", "sulfuric-acid-geyser" }, }, { x = 32, y = 16 }, { x = center_pos.x - 32, y = center_pos.y }, resource_amount_map, ore_entity_size)

  local rock_left_top = { x = center_pos.x - 32, y = center_pos.y - 32 }
  local rock_right_bottom = add_pos(rock_left_top, { x = 64, y = 32 })
  mg.create_rect_pos(rock_left_top, rock_right_bottom, { x = 8, y = 8 }, nil, function (pos)
    surface.create_entity({ name = "big-volcanic-rock", position = pos })
  end)

  rock_left_top = { x = center_pos.x - 32, y = center_pos.y }
  rock_right_bottom = add_pos(rock_left_top, { x = 64, y = 32 })
  mg.create_rect_pos(rock_left_top, rock_right_bottom, { x = 8, y = 8 }, nil, function (pos)
    surface.create_entity({ name = "vulcanus-chimney-faded", position = pos })
  end)

  local plants_left_top = { x = center_pos.x - 1, y = center_pos.y - 32 }
  local plants_right_bottom = add_pos(plants_left_top, { x = 3, y = 64 })
  mg.create_rect_pos(plants_left_top, plants_right_bottom, { x = 1, y = 1 }, { x = 1, y = 1 }, function (pos)
    surface.create_entity({ name = "ashland-lichen-tree", position = pos })
  end)
end

-- 雷神星
function mg.create_team_fulgora_area(force, center_pos, left_top, right_bottom)
  local surface = game.surfaces.fulgora
  local vaild_area_left_top, vaild_area_right_bottom = get_bounding_box_pos(center_pos, vaild_team_area)

  mg.create_rect_pos(left_top, right_bottom, { x = 1, y = 1 }, { x = 0, y = 0 }, function (pos)
    local is_vail_area = is_in_boundingbox(pos, vaild_area_left_top, vaild_area_right_bottom)
    local tile_name = "out-of-map"
    if is_vail_area then
      tile_name = "fulgoran-dunes"
    end
    surface.set_tiles({ { name = tile_name, position = pos } })
  end)

  mg.create_rect_edge_pos(vaild_area_left_top, vaild_area_right_bottom, { x = 1, y = 1 }, { x = 0, y = 0 }, function (pos)
    surface.set_tiles({ { name = "oil-ocean-shallow", position = pos, } })
  end)

  local resource_amount_map = {}
  local ore_entity_size = { ["sulfuric-acid-geyser"] = { x = 3, y = 4 } }

  local resource_left_top = { x = center_pos.x - 32, y = center_pos.y - 32 }
  create_ore_area(surface, { { "scrap" }, }, { x = 64, y = 64 }, resource_left_top, resource_amount_map, ore_entity_size)

  local rock_left_top = add_pos(center_pos, { x = -32, y = -32 })
  local rock_right_bottom = add_pos(rock_left_top, { x = 30, y = 30 })
  mg.create_rect_pos(rock_left_top, rock_right_bottom, { x = 12, y = 10 }, { x = 1, y = 1 }, function (pos)
    surface.create_entity({ name = "fulgoran-ruin-vault", position = pos })
  end)

  -- rock_left_top = add_pos(rock_left_top, { x = 4, y = -5 })
  -- rock_right_bottom = add_pos(rock_left_top, { x = 30, y = 10 })
  -- mg.create_rect_pos(rock_left_top, rock_right_bottom, { x = 20, y = 10 }, { x = 1, y = 1 }, function (pos)
  --   surface.create_entity({ name = "fulgoran-ruin-vault", position = pos })
  -- end)

  -- create plants
  local plants_left_top = add_pos(center_pos, { x = 2, y = -32 })
  local plants_right_bottom = add_pos(plants_left_top, { x = 28, y = 28 })
  mg.create_rect_pos(plants_left_top, plants_right_bottom, { x = 1, y = 1 }, { x = 2, y = 2 }, function (pos)
    surface.create_entity({ name = "fulgurite", position = pos })
  end)

  -- plants_left_top = add_pos(plants_left_top, { x = -2, y = 8 })
  -- plants_right_bottom = add_pos(plants_left_top, { x = 4, y = 28 })
  -- mg.create_rect_pos(plants_left_top, plants_right_bottom, { x = 1, y = 1 }, { x = 1, y = 1 }, function (pos)
  --   surface.create_entity({ name = "fulgurite", position = pos })
  -- end)
end

-- 巨芒星
function mg.create_team_gleba_area(force, center_pos, left_top, right_bottom)
  local surface = game.surfaces.gleba
  local vaild_area_left_top, vaild_area_right_bottom = get_bounding_box_pos(center_pos, vaild_team_area)


  mg.create_rect_pos(left_top, right_bottom, { x = 1, y = 1 }, { x = 0, y = 0 }, function (pos)
    local is_vail_area = is_in_boundingbox(pos, vaild_area_left_top, vaild_area_right_bottom)
    if not is_vail_area then
      surface.set_tiles({ { name = "out-of-map", position = pos } })
    end
  end)

  -- wetland
  mg.create_rect_edge_pos(vaild_area_left_top, vaild_area_right_bottom, { x = 16, y = 16 }, { x = 0, y = 0 }, function (pos)
    for x = -8, 7 do
      for y = -8, 7 do
        local newpos = add_pos(pos, { x = x, y = y })
        local name = "wetland-green-slime"
        if newpos.x < center_pos.x then
          name = "wetland-red-tentacle"
        end
        surface.set_tiles({ { name = name, position = newpos } })
      end
    end
  end)

  mg.create_rect_edge_pos(vaild_area_left_top, vaild_area_right_bottom, { x = 5, y = 5 }, { x = 2, y = 2 }, function (pos, edge)
    if edge == "top" then
      surface.create_entity{ name = "gleba-spawner", position = pos, force = force }
    end
  end)

  mg.create_rect_edge_pos(add_pos(vaild_area_left_top, { x = 8, y = 8 }), add_pos(vaild_area_right_bottom, { x = -8, y = -8 }), { x = 3, y = 3 }, { x = 5, y = 5 }, function (pos)
    surface.create_entity{ name = "slipstack", position = pos }
  end)

  -- left
  local yumako_left_top = add_pos(center_pos, { x = -48, y = -48 })
  local yumako_right_bottom = add_pos(yumako_left_top, { x = 48, y = 96 })
  mg.create_rect_pos(yumako_left_top, yumako_right_bottom, { x = 1, y = 1 }, { x = 0, y = 0 }, function (pos)
    surface.set_tiles({ { name = "natural-jellynut-soil", position = pos } })
  end)

  mg.create_rect_pos(yumako_left_top, yumako_right_bottom, { x = 3, y = 3 }, { x = 1, y = 1 }, function (pos)
    surface.create_entity{ name = "jellystem", position = pos }
  end)

  mg.create_rect_pos(yumako_left_top, yumako_right_bottom, { x = 3, y = 3 }, { x = 5, y = 5 }, function (pos)
    surface.create_entity{ name = "copper-stromatolite", position = pos }
  end)

  -- right
  local jellynut_left_top = add_pos(center_pos, { x = 0, y = -48 })
  local jellynut_right_bottom = add_pos(jellynut_left_top, { x = 48, y = 96 })
  mg.create_rect_pos(jellynut_left_top, jellynut_right_bottom, { x = 1, y = 1 }, { x = 0, y = 0 }, function (pos)
    surface.set_tiles({ { name = "natural-yumako-soil", position = pos } })
  end)

  mg.create_rect_pos(jellynut_left_top, jellynut_right_bottom, { x = 3, y = 3 }, { x = 1, y = 1 }, function (pos)
    surface.create_entity{ name = "yumako-tree", position = pos }
  end)

  mg.create_rect_pos(jellynut_left_top, jellynut_right_bottom, { x = 3, y = 3 }, { x = 5, y = 5 }, function (pos)
    surface.create_entity{ name = "iron-stromatolite", position = pos }
  end)

  -- stone
  local resource_left_top = { x = center_pos.x - 21, y = center_pos.y - 21 }
  create_ore_area(surface, { { "stone" } }, { x = 42, y = 42 }, resource_left_top)
end

-- 玄冥星
function mg.create_team_aquilo_area(force, center_pos, left_top, right_bottom)
  local surface = game.surfaces.aquilo
  local vaild_area_left_top, vaild_area_right_bottom = get_bounding_box_pos(center_pos, vaild_team_area)

  mg.create_rect_pos(left_top, right_bottom, { x = 1, y = 1 }, { x = 0, y = 0 }, function (pos)
    local is_vail_area = is_in_boundingbox(pos, vaild_area_left_top, vaild_area_right_bottom)
    if not is_vail_area then
      surface.set_tiles({ { name = "out-of-map", position = pos } })
    else
      surface.set_tiles({ { name = "dust-flat", position = pos } })
    end
  end)

  mg.create_rect_edge_pos(vaild_area_left_top, vaild_area_right_bottom, { x = 32, y = 32 }, { x = 0, y = 0 }, function (pos)
    for x = -16, 15 do
      for y = -16, 15 do
        surface.set_tiles({ { name = "ammoniacal-ocean", position = add_pos(pos, { x = x, y = y }) } })
      end
    end
  end)

  -- create oil-ocean-shallow
  local vent_area_left_top, vent_area_right_buttom = get_bounding_box_pos(center_pos, { x = 62, y = 64 })
  mg.create_rect_edge_pos(vent_area_left_top, vent_area_right_buttom, { x = 3, y = 3 }, 0, function (pos, edge)
    if edge == "left" then
      surface.create_entity({ name = "lithium-brine", position = pos, amount = 300000000, })
    elseif edge == "right" then
      surface.create_entity({ name = "fluorine-vent", position = pos, amount = 300000000, })
    end
  end)

  local rock_left_top = { x = center_pos.x - 32, y = center_pos.y - 2 }
  local rock_right_bottom = { x = center_pos.x + 32, y = center_pos.y + 2 }
  mg.create_rect_pos(rock_left_top, rock_right_bottom, { x = 2, y = 2 }, { x = 1, y = 1 }, function (pos)
    surface.create_entity{ name = "lithium-iceberg-big", position = pos }
  end)

  rock_left_top = { x = center_pos.x - 2, y = center_pos.y - 32 }
  rock_right_bottom = { x = center_pos.x + 2, y = center_pos.y + 32 }
  mg.create_rect_pos(rock_left_top, rock_right_bottom, { x = 2, y = 2 }, { x = 1, y = 1 }, function (pos)
    surface.create_entity{ name = "lithium-iceberg-big", position = pos }
  end)
end

return mg
