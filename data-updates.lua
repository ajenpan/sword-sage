data.raw["item"]["coin"].hidden = false


-- log("mech-armor allow_quality:" .. serpent.block(data.raw["recipe"]["mech-armor"]))
-- data.raw["recipe"]["mech-armor"].enabled = false

data.raw["recipe"]["mech-armor"].hidden = true
data.raw["recipe"]["radar"].enabled = false
data.raw["recipe"]["radar"].hidden = true
data.raw["item"]["radar"].hidden = true

data.raw["technology"]["radar"].enabled = false
data.raw["technology"]["artillery"].enabled = false
data.raw["technology"]["artillery-shell-damage-1"].enabled = false
data.raw["technology"]["artillery-shell-range-1"].enabled = false
data.raw["technology"]["artillery-shell-speed-1"].enabled = false
data.raw["technology"]["atomic-bomb"].enabled = false
 