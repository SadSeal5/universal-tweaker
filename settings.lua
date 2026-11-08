data:extend({
  -- Global Building Settings
  {
    type = "double-setting",
    name = "ut-global-crafting-speed",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.01,
    maximum_value = 100.0,
    order = "ba"
  },
  {
    type = "double-setting",
    name = "ut-global-mining-speed",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.01,
    maximum_value = 100.0,
    order = "bb"
  },
  {
    type = "int-setting",
    name = "ut-global-mining-radius",
    setting_type = "startup",
    default_value = 0,
    minimum_value = 0,
    maximum_value = 20,
    order = "bc"
  },
  {
    type = "double-setting",
    name = "ut-global-lab-speed",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.01,
    maximum_value = 100.0,
    order = "bd"
  },
  {
    type = "double-setting",
    name = "ut-global-energy-multiplier",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.0,
    maximum_value = 10.0,
    order = "be"
  },
  {
    type = "double-setting",
    name = "ut-global-pollution-multiplier",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.0,
    maximum_value = 10.0,
    order = "bf"
  },
  {
    type = "int-setting",
    name = "ut-global-extra-module-slots",
    setting_type = "startup",
    default_value = 0,
    minimum_value = 0,
    maximum_value = 20,
    order = "bg"
  },
  {
    type = "double-setting",
    name = "ut-global-base-productivity",
    setting_type = "startup",
    default_value = 0.0,
    minimum_value = 0.0,
    maximum_value = 10.0,
    order = "bh"
  },
  {
    type = "double-setting",
    name = "ut-global-building-health",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 50.0,
    order = "bi"
  },

  -- Global Weapon & Combat Settings
  {
    type = "double-setting",
    name = "ut-global-gun-damage",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 50.0,
    order = "wa"
  },
  {
    type = "double-setting",
    name = "ut-global-gun-range",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 20.0,
    order = "wb"
  },
  {
    type = "double-setting",
    name = "ut-global-gun-firerate",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 20.0,
    order = "wc"
  },
  {
    type = "double-setting",
    name = "ut-global-turret-damage",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 50.0,
    order = "wd"
  },
  {
    type = "double-setting",
    name = "ut-global-turret-range",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 20.0,
    order = "we"
  },
  {
    type = "double-setting",
    name = "ut-global-turret-firerate",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 20.0,
    order = "wf"
  },
  {
    type = "double-setting",
    name = "ut-global-ammo-damage",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 50.0,
    order = "wg"
  },

  -- Individual / Custom Overrides
  {
    type = "string-setting",
    name = "ut-custom-building-overrides",
    setting_type = "startup",
    default_value = "",
    allow_blank = true,
    order = "oa"
  },
  {
    type = "string-setting",
    name = "ut-custom-weapon-overrides",
    setting_type = "startup",
    default_value = "",
    allow_blank = true,
    order = "ob"
  },
  {
    type = "double-setting",
    name = "ut-override-assembler3-speed",
    setting_type = "startup",
    default_value = 1.25,
    minimum_value = 0.1,
    maximum_value = 100.0,
    order = "oc"
  },
  {
    type = "int-setting",
    name = "ut-override-assembler3-modules",
    setting_type = "startup",
    default_value = 4,
    minimum_value = 0,
    maximum_value = 30,
    order = "od"
  },
  {
    type = "double-setting",
    name = "ut-override-electric-drill-speed",
    setting_type = "startup",
    default_value = 0.5,
    minimum_value = 0.05,
    maximum_value = 50.0,
    order = "oe"
  },
  {
    type = "double-setting",
    name = "ut-override-laser-turret-range",
    setting_type = "startup",
    default_value = 24.0,
    minimum_value = 1.0,
    maximum_value = 200.0,
    order = "of"
  },
  {
    type = "double-setting",
    name = "ut-override-laser-turret-damage",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 50.0,
    order = "og"
  }
})
