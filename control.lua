local gm = require("script.game_manager")


script.on_init(function (event)
  log("sword-sage start on_init")
  gm.on_init(event)
end)
