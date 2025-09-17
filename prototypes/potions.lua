local sounds = require("__base__/prototypes/entity/sounds.lua")

function add_potion(name, icon, cooldown, heal)
  data:extend({
    {
      type = "capsule",
      name = name,
      icon = icon,
      icon_size = 64,
      subgroup = "raw-resource",
      capsule_action =
      {
        type = "use-on-self",
        attack_parameters =
        {
          type = "projectile",
          activation_type = "consume",
          ammo_category = "capsule",
          cooldown = cooldown,
          range = 0,
          ammo_type =
          {
            category = "capsule",
            target_type = "position",
            action =
            {
              type = "direct",
              action_delivery =
              {
                type = "instant",
                target_effects =
                {
                  {
                    type = "damage",
                    damage = { type = "physical", amount = heal }
                  },
                  {
                    type = "play-sound",
                    sound = sounds.eat_fish
                  }
                }
              }
            }
          }
        }
      },
      order = "h[raw-fish]",
      stack_size = 100
    }
  })
end

add_potion("rpg_amnesia_potion", "__chinese-xianxia__/graphics/amnesia_potion.png", 120, -1)
add_potion("rpg_level_up_potion", "__chinese-xianxia__/graphics/xp_potion_up.png", 120, -1)
add_potion("rpg_small_xp_potion", "__chinese-xianxia__/graphics/xp_potion_1.png", 120, -1)
add_potion("rpg_big_xp_potion", "__chinese-xianxia__/graphics/xp_potion_2.png", 120, -1)
add_potion("rpg_crafting_potion", "__chinese-xianxia__/graphics/crafting_potion.png", 120, -1)
add_potion("rpg_speed_potion", "__chinese-xianxia__/graphics/speed_potion.png", 120, -1)
add_potion("rpg_small_healing_potion", "__chinese-xianxia__/graphics/healing_potion_s.png", 400, -120)
add_potion("rpg_big_healing_potion", "__chinese-xianxia__/graphics/healing_potion_b.png", 600, -240)
add_potion("rpg_curse_cure_potion", "__chinese-xianxia__/graphics/curse_cure_potion.png", 120, -1)
