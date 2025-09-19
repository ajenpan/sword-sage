local ShopItems = {
  ["equipment"] = {
    { target_item = { name = "mech-armor", count = 1, quality = "legendary" }, price_item = { name = "coin", count = 1e5, } },
    { target_item = { name = "fusion-reactor-equipment", count = 1, quality = "legendary" }, price_item = { name = "coin", count = 1e5, } },
    { target_item = { name = "battery-mk3-equipment", count = 1, quality = "legendary" }, price_item = { name = "coin", count = 1e5, } },
    { target_item = { name = "toolbelt-equipment", count = 1, quality = "legendary" }, price_item = { name = "coin", count = 1e5, } },
    { target_item = { name = "personal-roboport-mk2-equipment", count = 1, quality = "legendary" }, price_item = { name = "coin", count = 1e5, } },
    { target_item = { name = "exoskeleton-equipment", count = 1, quality = "legendary" }, price_item = { name = "coin", count = 1e5, } },
    { target_item = { name = "energy-shield-mk2-equipment", count = 1, quality = "legendary" }, price_item = { name = "coin", count = 1e5, } },
    { target_item = { name = "personal-laser-defense-equipment", count = 1, quality = "legendary" }, price_item = { name = "coin", count = 1e5, } },
  },
  ["vehicle"] = {
    { target_item = { name = "spidertron", count = 1, quality = "normal", }, price_item = { name = "coin", count = 1e5, } },
    { target_item = { name = "spidertron", count = 1, quality = "legendary", }, price_item = { name = "coin", count = 1e5, } },
  }
}

local shop = {}

local function exchange(player, target_item, price_item)
  local player_inv = player.get_inventory(defines.inventory.character_main)
  local real_offercnt = player_inv.remove(price_item)
  if real_offercnt < price_item.count then
    return false
  end
  player_inv.insert(target_item)
end

local function exchange_all_item(player, target_item, price_item, exchange_rate)
  local owncnt = player.get_item_count(price_item)
  local targetcnt = math.floor(owncnt / exchange_rate)

  if (targetcnt <= 0) then
    player.print("没有满足兑换条件的物品，请检查背包至少拥有" .. exchange_rate)
    return false
  end
  local offercnt = targetcnt * exchange_rate

  local real_offercnt = player.remove_item({ name = price_item.name, count = offercnt, quality = price_item.quality })

  if real_offercnt >= offercnt then
    player.insert{ name = target_item.name, count = targetcnt, quality = target_item.quality }

    local msg = string.format("道友 [color=#00ffff]%s[/color] 使用%d个[item=%s,quality=%s]兑换%d个[item=%s,quality=%s]",
      player.name, offercnt, price_item.name.price_item.quality, targetcnt, target_item.name, target_item.quality)

    game.print(msg)
  end

  return true
end

local function reflash_shop_pane(player)
  if not (storage.shop and storage.shop.gui_root) then return end
  storage.shop.gui_root.clear()
  shop.create_shop_pane(storage.shop.gui_root, player)
end

local function on_click_item(event)
  local element = event.element
  if not (element and element.valid) then return end
  local player = game.players[event.player_index]
  -- todo : 支持 shift 和 ctrl
  local item = element.tags.item
  exchange(player, item.target_item, item.price_item)
  reflash_shop_pane(player)
end

function shop.create_shop_pane(frame, player)
  if not (frame and player) then return end

  if not (player.character and player.character.valid) then
    return
  end

  local player_inv = player.character.get_main_inventory()
  if (player_inv == nil) then
    log("shop player main inventory is nil")
    return
  end

  if storage.shop == nil then
    storage.shop = {}
  end
  storage.shop.gui_root = frame


  g_uih.add(frame, { type = "line" })

  -- local wallet = player_inv.get_item_count("coin")
  -- g_uih.add(frame, { type = "label", caption = "拥有金币:" .. wallet .. "[item=coin]", style_table = { top_margin = 5, bottom_margin = 5 } })

  -- AddLabel(tab_container, "player_coins", "拥有金币: " .. wallet .. "  [item=coin]", { top_margin = 5, bottom_margin = 5 })
  -- local line = tab_container.add{ type = "line", direction = "horizontal" }
  -- line.style.top_margin = 5
  -- line.style.bottom_margin = 5

  for category, section in pairs(ShopItems) do
    local flow = frame.add{ name = "shop.category." .. category, type = "flow", direction = "horizontal" }

    for i, item in ipairs(section) do
      local target_item = item.target_item
      local price_item = item.price_item

      if (not prototypes.item[target_item.name] or not prototypes.item[price_item.name]) then
        log("ERROR: Item not found in storage.ocfg.shop_items: " .. target_item.name)
        goto continue
      end

      local wallet = player_inv.get_item_count(price_item)
      local enabled = wallet >= price_item.count
      local color = "[color=red]"
      if (enabled) then
        color = "[color=green]"
      end

      local btn = g_uih.add(flow, {
        name = "shop.item." .. string.format("%s_%02d", category, i),
        type = "sprite-button",
        number = item.count,
        sprite = "item/" .. target_item.name,
        tooltip = string.format("需要: %s%d[/color][item=%s,quality=%s]",
          color, price_item.count, price_item.name, price_item.quality),
        style = "slot_button",
        enabled = enabled,
        quality = target_item.quality,
        on_click = on_click_item,
        style_table = { size = { 60, 60 } },
        tags = {
          action = "store_item",
          item = item,
          category = category
        }
      })

      ::continue::
    end

    g_uih.add(frame, { type = "line", direction = "horizontal", style_table = { top_margin = 5, bottom_margin = 5 } })
  end
end

function shop.on_gui_click(event)
  if not (event.element and event.element.valid) then return end


  -- local element = event.element
  -- local player = game.players[event.player_index]
  -- if (element.tags.action == "store_item") then
  --   local item = element.tags.item
  --   exchange(player, item.target_item, item.price_item)
  -- end
end

return shop
