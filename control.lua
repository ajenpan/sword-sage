local gm = require("script.game_manager")

script.on_init(function (event)
  log("on_init")
  gm.on_init(event)
end)
