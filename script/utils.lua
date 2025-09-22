CHUNK_SIZE = 32
MAX_FORCES = 64
TICKS_PER_SECOND = 60
TICKS_PER_MINUTE = TICKS_PER_SECOND * 60
TICKS_PER_HOUR = TICKS_PER_MINUTE * 60

MAX_INT32_POS = 2147483647
MAX_INT32_NEG = -2147483648

local utils = {}


function utils.markup_wrap(markup_key, value)
  return function (content)
    return string.format("[%s=%s]%s[/%s]", markup_key, value, content, markup_key)
  end
end

function utils.item_text(name, cnt, quality)
  if not cnt then cnt = 1 end
  if not quality then quality = "normal" end
  return string.format("[item=%s,count=%s,quality=%s]", name, cnt, quality)
end

function utils.to_short_num_str(number)
  local steps = {
    { 1, "" },
    { 1e3, "k" },
    { 1e6, "m" },
    { 1e9, "g" },
    { 1e12, "t" },
  }
  for _, b in ipairs(steps) do
    if b[1] <= number + 1 then
      steps.use = _
    end
  end
  local result = string.format("%.1f", number / steps[steps.use][1])
  if tonumber(result) >= 1e3 and steps.use < #steps then
    steps.use = steps.use + 1
    result = string.format("%.1f", tonumber(result) / 1e3)
  end
  return result .. steps[steps.use][2]
end

function utils.to_cn_num_str(n)
  local digits = { "零", "一", "二", "三", "四", "五", "六", "七", "八", "九" }
  if n < 10 then
    return digits[n + 1]
  elseif n < 20 then
    if n == 10 then
      return "十"
    else
      return "十" .. digits[(n % 10) + 1]
    end
  else
    local tens = math.floor(n / 10)
    local ones = n % 10
    if ones == 0 then
      return digits[tens + 1] .. "十"
    else
      return digits[tens + 1] .. "十" .. digits[ones + 1]
    end
  end
end

function utils.format_dd_count(dd_count)
  local ranges = {
    { lower = 1e5, upper = 1e9, divisor = 1e4, suffix = "万" },
    { lower = 1e9, upper = 1e13, divisor = 1e8, suffix = "亿" },
    { lower = 1e13, upper = 1e17, divisor = 1e12, suffix = "兆" },
    { lower = 1e17, upper = 1e21, divisor = 1e16, suffix = "京" },
    { lower = 1e21, upper = 1e25, divisor = 1e20, suffix = "垓" },
    { lower = 1e25, upper = 1e29, divisor = 1e24, suffix = "秭" },
    { lower = 1e29, upper = 1e33, divisor = 1e28, suffix = "穰" },
    { lower = 1e33, upper = 1e37, divisor = 1e32, suffix = "沟" },
    { lower = 1e37, upper = 1e41, divisor = 1e36, suffix = "涧" },
    { lower = 1e41, upper = 1e45, divisor = 1e40, suffix = "正" },
    { lower = 1e45, upper = 1e49, divisor = 1e44, suffix = "载" },
    { lower = 1e49, upper = 1e53, divisor = 1e48, suffix = "极" },
    { lower = 1e53, upper = 1e57, divisor = 1e52, suffix = "恒河沙" },
    { lower = 1e57, upper = 1e61, divisor = 1e56, suffix = "阿僧祗" },
    { lower = 1e61, upper = 1e65, divisor = 1e60, suffix = "那由他" },
    { lower = 1e65, upper = 1e69, divisor = 1e64, suffix = "不可思议" },
    { lower = 1e69, upper = math.huge, divisor = 1e68, suffix = "无穷尽" }
  }
  for _, range in ipairs(ranges) do
    if dd_count > range.lower and dd_count <= range.upper then
      return math.floor(dd_count / range.divisor) .. range.suffix
    end
  end
  return dd_count
end

utils.colors_hex = {
  red = "#FF0000"
}

utils.colors_tab = {
  white = { r = 1, g = 1, b = 1 },
  black = { r = 0, g = 0, b = 0 },
  darkgrey = { r = 0.25, g = 0.25, b = 0.25 },
  grey = { r = 0.5, g = 0.5, b = 0.5 },
  lightgrey = { r = 0.75, g = 0.75, b = 0.75 },

  red = { r = 1, g = 0, b = 0 },
  darkred = { r = 0.5, g = 0, b = 0 },
  lightred = { r = 1, g = 0.5, b = 0.5 },
  green = { r = 0, g = 1, b = 0 },
  darkgreen = { r = 0, g = 0.5, b = 0 },
  lightgreen = { r = 0.5, g = 1, b = 0.5 },
  blue = { r = 0, g = 0, b = 1 },
  darkblue = { r = 0, g = 0, b = 0.5 },
  lightblue = { r = 0.5, g = 0.5, b = 1 },

  orange = { r = 1, g = 0.55, b = 0.1 },
  yellow = { r = 1, g = 1, b = 0 },
  pink = { r = 1, g = 0, b = 1 },
  purple = { r = 0.6, g = 0.1, b = 0.6 },
  brown = { r = 0.6, g = 0.4, b = 0.1 },
}


return utils
