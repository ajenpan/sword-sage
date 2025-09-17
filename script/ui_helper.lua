-- local ui = require("script.ui_frame")
local uih = {
  on_click_register = {}
}

function uih.apply_style(element, style_in)
  for k, v in pairs(style_in) do
    element.style[k] = v
  end
  return element
end

function uih.add(parant, children)
  local child_element = nil
  if children[1] == nil then
    local style = children.style_table
    local has_style = type(style) == "table"
    if has_style then
      children.style_table = nil
    end

    local on_click = children.on_click
    local name = children.name
    if name and on_click then
      children.on_click = nil
    end

    child_element = parant.add(children)

    if has_style then
      uih.apply_style(child_element, style)
    end

    if name and on_click then
      uih.on_click_register[string.format("%d_%s", parant.player_index, name)] = on_click
    end
  else
    child_element = {}
    for k, v in ipairs(children) do
      child_element[k] = uih.add(parant, v)
    end
  end
  return child_element
end

function uih.on_gui_click(event)
  local element = event.element
  if not (element and element.valid) then return end
  if element.name then
    local key = string.format("%d_%s", element.player_index, element.name)
    local cb = uih.on_click_register[key]
    if cb then
      cb(event)
    end
  end
end

return uih
