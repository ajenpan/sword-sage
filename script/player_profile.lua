local mod_gui = require("mod-gui")
local util = require("util")
local uih = require("script.ui_helper")

local Attributes = {
  "STR", -- 力量 加伤害,背包容量,挖矿速度
  "DEX", -- 敏捷 加暴击
  "LUK", -- 幸运 加掉落率
  "CON", -- 体力 加血量
  "SPI", -- 精神 加交互范围.
  "INT", -- 智力 加研究速度.制作速度
}

local pf = {}

function pf.exp_required(level)
  local base = 2000
  local growth = 1.1
  return math.floor(base * (level ^ growth))
end

local max_level = 20

local xp_required_table = {}
for i = 1, max_level do
  xp_required_table[i] = pf.exp_required(i)
end
pf.xp_required_table = xp_required_table


function pf.on_init()
  if storage.player_profile == nil then
    storage.player_profile = {}
  end

  for i, info in pairs(storage.player_profile) do
    LogI("player_profile:", info)
  end
end

-- todo: 根据转生次数提高经验要求??
function pf.get_required_xp(lv)
  if lv > 0 and lv <= max_level then
    return pf.xp_required_table[lv]
  end
  return 0
end

function pf.get_player_level(player)
  local storage = pf.player_profile(player)
  return storage.level
end

function pf.get_player_ascension_cnt(player)
  return pf.player_profile(player).ascension_cnt
end

function pf.player_profile(player)
  local s = storage.player_profile
  if s[player.index] == nil then
    s[player.index] = {
      ascension_cnt = 1,
      assigned_ap = {},
      usable_ap = 1,
      level = 1,
      xp = 0,
    }
  end
  return s[player.index]
end

function pf.get_player_ap(player, attrib)
  local ap = pf.player_profile(player).assigned_ap
  if attrib == nil then
    return ap
  end
  local point = ap[attrib]
  if point == nil then
    point = 0
    ap[attrib] = point
  end
  return point
end

function pf.inc_player_ap(player, attrib, inc)
  if inc == nil or inc <= 0 then
    inc = 1
  end

  local profile = pf.player_profile(player)
  if not (profile and profile.usable_ap >= inc) then
    return
  end
  local character = player.character
  if not (character and character.valid) then
    player.print("没有玩家实体, 加成无效")
    return
  end

  if not profile.assigned_ap[attrib] then
    profile.assigned_ap[attrib] = 0
  end

  profile.usable_ap = profile.usable_ap - inc
  profile.assigned_ap[attrib] = profile.assigned_ap[attrib] + inc

  -- effect

  if attrib == "CON" then
    character.character_health_bonus = character.character_health_bonus + 100 * inc
  elseif attrib == "SPI" then
    character.character_resource_reach_distance_bonus = character.character_resource_reach_distance_bonus + 1 * inc
    character.character_reach_distance_bonus = character.character_reach_distance_bonus + 1 * inc
    character.character_item_drop_distance_bonus = character.character_item_drop_distance_bonus + 1 * inc
    character.character_build_distance_bonus = character.character_build_distance_bonus + 1 * inc
    character.character_item_pickup_distance_bonus = character.character_item_pickup_distance_bonus + 1 * inc
    character.character_loot_pickup_distance_bonus = character.character_loot_pickup_distance_bonus + 1 * inc
  elseif attrib == "DEX" then
    character.character_running_speed_modifier = character.character_running_speed_modifier + 0.2 * inc
  elseif attrib == "STR" then
    player.character.character_inventory_slots_bonus = player.character.character_inventory_slots_bonus + 5 * inc
    player.character_mining_speed_modifier = player.character_mining_speed_modifier + 0.1 * inc
  elseif attrib == "INT" then
    player.character_crafting_speed_modifier = player.character_crafting_speed_modifier + 0.1 * inc
    player.character_maximum_following_robot_count_bonus = player.character_maximum_following_robot_count_bonus + 1 * inc
  end
end

function pf.create_profile_pane(frame, player)
  if not (player.character and player.character.valid) then return end

  local profile = pf.player_profile(player)
  profile.gui_root = frame

  local lv = profile.level
  local hp = math.ceil(player.character.health)
  local xp = profile.xp
  local usable_ap = profile.usable_ap

  local ptime = player.online_time
  local timestr = string.format("%d:%02d:%02d", math.floor(ptime / 216000), math.floor(ptime / 3600) % 60, math.floor(ptime / 60) % 60)

  uih.add(frame, { type = "line" })

  local tabChar = uih.add(frame, { type = "table", column_count = 2 })
  local profile_pane = uih.add(tabChar, { type = "scroll-pane", vertical_scroll_policy = "auto", horizontal_scroll_policy = "auto", style_table = { padding = { -5, 0, 5, 10 } } })

  uih.add(profile_pane, { type = "label", caption = player.name, style_table = { font = "font_default_bold_30" } })

  uih.add(profile_pane, { type = "label", caption = { "actual_lv", lv }, style_table = { font = "font_default_18" } })
  uih.add(profile_pane, { type = "label", caption = "经验: " .. util.format_number(xp) .. "/" .. util.format_number(pf.get_required_xp(lv)), style_table = { font = "font_default_18" } })
  uih.add(profile_pane, { type = "label", caption = "生命值: " .. util.format_number(hp), style_table = { font = "font_default_18" } })
  uih.add(profile_pane, { type = "label", caption = { "time-played", timestr }, style_table = { font = "font_default_18" } })

  uih.add(frame, { type = "line" })
  uih.add(frame, { type = "label", caption = { "usable_ap", usable_ap }, style_table = { font = "default-bold" } })

  local ap_pane = uih.add(frame, { type = "table", column_count = 2, style_table = { horizontal_spacing = 10, vertical_spacing = 10, padding = { 0, 0, 5, 10 } } })

  local attrib_point = pf.get_player_ap(player)

  for i = 1, #Attributes do
    local attrib = Attributes[i]

    local attrib_display = "player_profile.attributes.display." .. attrib
    local attrib_tooltip = "player_profile.attributes.tooltip." .. attrib

    uih.add(
      uih.add(ap_pane, { type = "table", column_count = 3, style_table = { width = 330, vertical_align = "center" } }),
      {
        { type = "label", caption = { attrib_display, attrib_point[attrib] or 0 }, tooltip = { attrib_tooltip }, style_table = { width = 80 } },
        -- { type = "flow", direction = "horizontal", style_table = { horizontally_stretchable = true, maximal_width = 30 } },
        { type = "empty-widget", style = "draggable_space", style_table = { width = 20 } },
        { type = "sprite-button", sprite = "assign_points_sprite", name = "assign_point_" .. attrib, visible = usable_ap > 0, enabled = usable_ap > 0, style_table = { height = 20, width = 20 } },
      }
    )
  end
  frame.add{ type = "line" }
end

function pf.on_player_get_xp(player, xp)
  if xp <= 0 then
    return
  end
  xp = math.ceil(xp)
  local s = pf.player_profile(player)
  s.xp = s.xp + xp

  local required_xp = pf.get_required_xp(s.level)
  if s.xp >= required_xp then
    s.xp = 0
    pf.on_player_level_up(player)
  end
end

function pf.on_player_level_up(player)
  local s = pf.player_profile(player)
  s.level = s.level + 1
  s.usable_ap = s.usable_ap + 1

  player.print("恭喜升级, 当前等级:" .. s.level)

  -- 按 RPG 传统, 升级时血条回满
  if player.character and player.character.valid then
    player.character.health = player.character.max_health
  end
end

function pf.on_entity_died(event)
  local entity = event.entity
  if entity.force.name ~= "enemy" then
    return
  end
  if not (event.cause and event.cause.type == "character") then
    return
  end
  local player = (event.cause and event.cause.player or nil)
  if player == nil then
    return
  end

  local base_xp = entity.prototype.get_max_health()
  local evoluation_mult = entity.force.get_evolution_factor(entity.surface)
  local type_mult = 1
  if entity.type == "unit-spawner" then
    type_mult = 2
  elseif entity.type == "turret" then
    type_mult = 1.5
  end
  local quality_mult = 1 -- math.ceil (entity.quality.level + 1) / 3
  local xp = base_xp * evoluation_mult * type_mult * quality_mult
  -- game.print(string.format("base_xp=%d, evo_mlt=%d, type_mult=%d,quality_mult=%d,quality:%d ",
  --   base_xp, evoluation_mult, type_mult, quality_mult, entity.quality.level))
  -- game.print("on_entity_died, get xp: " .. xp)
  pf.on_player_get_xp(player, xp)
end

function pf.on_entity_damaged(event)
  local entity = event.entity

  local filterlist = {
    { filter = "type", type = "unit" },
    { filter = "type", type = "unit-spawner" },
    { filter = "type", type = "wall" },
    { filter = "type", type = "gate" },
    { filter = "type", type = "spider-vehicle" },
    { filter = "type", type = "car" },
    { filter = "type", type = "electric-turret" },
    { filter = "type", type = "artillery-turret" },
    { filter = "type", type = "ammo-turret" },
    { filter = "type", type = "fluid-turret" },
    { filter = "type", type = "turret" },
    { filter = "type", type = "character" },
  }

  local passfilter = false
  for _, v in ipairs(filterlist) do
    if entity[v.filter] == v.type then
      passfilter = true
      break
    end
  end

  if not passfilter then
    return
  end

  local damage_type = event.damage_type
  local original_damage_amount = event.original_damage_amount
  local cause = event.cause
  local final_dmg = event.final_damage_amount

  if cause and cause.valid and entity and entity.valid and entity.health > 0 and damage_type and original_damage_amount then
    -- NATURAL ARMOR
    if final_dmg > 0 and entity.type == "character" then
      local player = entity.player
      if player and player.valid then
        local armor_lv = storage.personalxp.LV_Armor_Bonus[player.name]
        if armor_lv > 0 then
          local bonus = (storage.RPG_Bonus.LV_Armor_Bonus * armor_lv)
          local recover = final_dmg * bonus / 100
          entity.health = entity.health + recover
        end
      end
    end

    -- DAMAGE BONUS
    if cause.type == "character" and damage_type.name ~= "poison" and damage_type.name ~= "cold" then
      local player = cause.player
      if player and player.valid then
        local dmg_lv = storage.personalxp.LV_Damage_Bonus[player.name]
        local critical_lv = storage.personalxp.LV_Damage_Critical[player.name]
        local new_damage = original_damage_amount
        if dmg_lv > 0 then
          local bonus = 1 + (storage.RPG_Bonus.LV_Damage_Bonus * dmg_lv / 100)
          new_damage = original_damage_amount * bonus
        end

        -- CRITICAL HITS
        -- if critical_lv > 0 and (string.find(entity.type, "unit") or string.find(entity.type, "turret")
        --       or entity.type == "car" or entity.type == "character" or entity.type == "spider-vehicle") then
        --   local proba = 100
        --   if damage_type.name == "fire" then proba = proba * 60 end --because damage per tick
        --   if math.random(proba) <= critical_lv * storage.RPG_Bonus["LV_Damage_Critical"] then
        --     new_damage = math.ceil(new_damage * (5 + critical_lv / 2))
        --     if (not storage.last_critical_effect_from[player.name]) or storage.last_critical_effect_from[player.name] + 60 * stg_critical_interval < game.tick then
        --       storage.last_critical_effect_from[player.name] = game.tick
        --       create_crithit_effect(entity, critical_lv, new_damage)
        --     end
        --   end
        -- end

        if new_damage > original_damage_amount then
          if entity.valid then
            entity.health = entity.health + final_dmg
            entity.damage(new_damage, player.force, damage_type)
            ---- this does not fire the event again according api
            ----damage(damage, force, type?, source?, cause?)
          end
        end
      end
    end
  end
end

function pf.on_research_finished(event)
  -- 研究完成加经验
  -- 加多少待定
end

-- script.on_event(defines.events.on_pre_player_died, function (event)
--   local player = game.players[event.player_index]
--   local name = player.name
--   storage.potion_effects[name] = {}
--   local XP = storage.personalxp.XP[name]
--   local Level = storage.personalxp.Level[name]
--   local NextLevel = storage.xp_table[Level]
--   if not NextLevel then return end

--   local XP_ant
--   if Level == 1 then XP_ant = 0 else XP_ant = storage.xp_table[Level - 1] end
--   local Interval_XP = NextLevel - XP_ant
--   local Penal = math.floor((XP - XP_ant) * storage.setting_death_penal / 100)
--   storage.personalxp.Death[name] = storage.personalxp.Death[name] + 1
--   storage.handle_respawn[name] = true
--   if Penal > 0 then
--     storage.personalxp.XP[name] = storage.personalxp.XP[name] - Penal
--     player.print({ "", { "xp_lost" }, RPG_format_number(Penal) }, colors.lightred)
--   end
-- end)

function pf.on_10_minute(event)
  for _, player in pairs(game.connected_players) do
    local xp = 100
    pf.on_player_get_xp(player, xp)
    player.print("道友勤修不辍，获得天道馈赠[color=#ffff00]" .. xp .. "[/color]经验")
  end
end

function pf.on_gui_click(event)
  local element = event.element
  if not (element and element.valid) then
    return
  end

  local player = game.players[element.player_index]
  local function get_assign_suffix(s)
    local prefix = "assign_point_"
    if #s > #prefix and s:sub(1, #prefix) == prefix then
      return true, s:sub(#prefix + 1)
    end
    return false, nil
  end

  local has_suffix, attrib = get_assign_suffix(element.name)
  if has_suffix then
    pf.on_player_assign_point(player, attrib)
  end
end

function pf.on_player_assign_point(player, attrib)
  pf.inc_player_ap(player, attrib)
  pf.reflash_player_profile_gui(player)
end

function pf.reflash_player_profile_gui(player)
  local guiroot = pf.player_profile(player).gui_root
  if not (guiroot and guiroot.valid) then
    return
  end
  guiroot.clear()
  pf.create_profile_pane(guiroot, player)
end

--
function pf.get_player_title(ascension_cnt, with_bracket)
  local title_list = { "凡人", "炼气", "筑基", "金丹", "元婴", "化神", "炼虚", "合体", "大乘", "渡劫", "天仙", "真仙", "玄仙", "金仙", "太乙", "大罗", "仙君", "仙尊", "仙王", "仙帝" }
  local color_list = { "#ffffff", "#33ff33", "#B7EF34", "#33BFFF", "#3100F4", "#ff33ff", "#ff3333", "#ffc0cb", "#ffd733", "#FD079F" }
  if not ascension_cnt or ascension_cnt <= 0 then
    ascension_cnt = 1
  end

  local max_title = #title_list
  local title = ""
  if ascension_cnt <= max_title then
    title = title_list[ascension_cnt]
  else
    title = title_list[#title_list] .. g_utils.to_cn_num_str(ascension_cnt - max_title) .. "重"
  end

  if with_bracket then
    title = "【" .. with_bracket .. "】"
  end

  local color_index = (math.abs(ascension_cnt) - 1) % #color_list + 1
  local color = color_list[color_index]

  local font = "default"
  if ascension_cnt >= 20 then
    font = "default-large-bold"
  elseif ascension_cnt >= 10 then
    font = "default-bold"
  end

  title = g_utils.markup_wrap("color", color)(title)
  title = g_utils.markup_wrap("font", font)(title)
  return title
end

return pf
