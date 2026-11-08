-- Universal Entity & Weapon Tweaker - data-final-fixes.lua
-- Factorio 2.1 Mod

local function get_setting(name, default)
  if settings.startup[name] and settings.startup[name].value ~= nil then
    return settings.startup[name].value
  end
  return default
end

-- ============================================================================
-- 1. Parse Energy Strings and Format
-- ============================================================================
local function parse_energy(str)
  if type(str) ~= "string" then return nil end
  local num_str, prefix, unit = string.match(str, "^%s*([%d%.eE+-]+)%s*([kKMGTPE]?)([wWjJ]?)%s*$")
  if not num_str then return nil end
  local num = tonumber(num_str)
  if not num then return nil end
  local multiplier = 1
  local p = string.upper(prefix or "")
  if p == "K" then multiplier = 1e3
  elseif p == "M" then multiplier = 1e6
  elseif p == "G" then multiplier = 1e9
  elseif p == "T" then multiplier = 1e12
  elseif p == "P" then multiplier = 1e15
  end
  local u = string.upper(unit or "")
  if u ~= "J" then u = "W" end
  return num * multiplier, u
end

local function format_energy(value, unit)
  unit = unit or "W"
  if value < 0.001 then
    return "0.001" .. unit
  end

  local function format_num(val)
    local s = string.format("%.3f", val)
    s = string.gsub(s, "%.(%d-)0+$", ".%1")
    s = string.gsub(s, "%.$", "")
    return s
  end

  if value >= 1e9 then
    return format_num(value / 1e9) .. "G" .. unit
  elseif value >= 1e6 then
    return format_num(value / 1e6) .. "M" .. unit
  elseif value >= 1e3 then
    return format_num(value / 1e3) .. "k" .. unit
  else
    return format_num(value) .. unit
  end
end

local function scale_energy(str, mult)
  if not str or mult == 1.0 then return str end
  local val, unit = parse_energy(str)
  if not val then return str end
  if mult <= 0 or (val * mult) < 0.001 then
    return "0.001" .. unit
  end
  local new_val = val * mult
  return format_energy(new_val, unit)
end

-- ============================================================================
-- 2. Pollution Scaling
-- ============================================================================
local function scale_pollution(proto, mult)
  if not proto or mult == 1.0 then return end
  local es = proto.energy_source
  if es and es.emissions_per_minute then
    if type(es.emissions_per_minute) == "table" then
      for k, v in pairs(es.emissions_per_minute) do
        if type(v) == "number" then
          es.emissions_per_minute[k] = v * mult
        end
      end
    elseif type(es.emissions_per_minute) == "number" then
      es.emissions_per_minute = es.emissions_per_minute * mult
    end
  end
end

-- ============================================================================
-- 3. Module Slots & Allowed Effects
-- ============================================================================
local function ensure_module_effects(proto)
  if not proto then return end

  if type(proto.allowed_effects) == "string" then
    proto.allowed_effects = { proto.allowed_effects }
  end

  local target_effects
  if proto.type == "beacon" then
    target_effects = {"consumption", "speed", "pollution"}
  else
    target_effects = {"consumption", "speed", "pollution"}
    if proto.name ~= "recycler" then
      table.insert(target_effects, "productivity")
    end
    if (mods and mods["quality"]) or (data and data.raw and data.raw["quality"]) then
      table.insert(target_effects, "quality")
    end
  end

  if not proto.allowed_effects then
    proto.allowed_effects = {}
    for _, eff in ipairs(target_effects) do
      table.insert(proto.allowed_effects, eff)
    end
  else
    local has = {}
    local filtered = {}
    for _, eff in ipairs(proto.allowed_effects) do
      if proto.type == "beacon" and (eff == "productivity" or eff == "quality") then
        -- Never allow productivity or quality on beacons
      elseif proto.name == "recycler" and eff == "productivity" then
        -- Never allow productivity on recycler
      elseif eff == "quality" and not ((mods and mods["quality"]) or (data and data.raw and data.raw["quality"])) then
        -- Never allow quality if quality mod is not enabled
      else
        table.insert(filtered, eff)
        has[eff] = true
      end
    end
    for _, req in ipairs(target_effects) do
      if not has[req] then
        table.insert(filtered, req)
        has[req] = true
      end
    end
    proto.allowed_effects = filtered
  end
end

-- ============================================================================
-- 4. Base Productivity Helper (Factorio 2.0+ effect_receiver)
-- ============================================================================
local function add_base_productivity(proto, bonus)
  if not proto or proto.name == "recycler" or not bonus or bonus == 0 then return end
  proto.effect_receiver = proto.effect_receiver or {}
  proto.effect_receiver.base_effect = proto.effect_receiver.base_effect or {}
  proto.effect_receiver.base_effect.productivity = (proto.effect_receiver.base_effect.productivity or 0) + bonus
end

local function set_base_productivity(proto, val)
  if not proto or proto.name == "recycler" or not val then return end
  proto.effect_receiver = proto.effect_receiver or {}
  proto.effect_receiver.base_effect = proto.effect_receiver.base_effect or {}
  proto.effect_receiver.base_effect.productivity = val
end

-- ============================================================================
-- 5. Attack Parameters & Beam Weapons Scaling
-- ============================================================================
local function update_beam_deliveries(ap, new_range)
  if not ap or not ap.ammo_type then return end
  local function scan(node)
    if type(node) ~= "table" then return end
    if node.type == "beam" then
      node.max_length = new_range
    end
    for _, v in pairs(node) do
      if type(v) == "table" then
        scan(v)
      end
    end
  end
  scan(ap.ammo_type)
end

local function scale_attack_parameters(ap, damage_mult, range_mult, firerate_mult)
  if not ap then return end
  if damage_mult and damage_mult ~= 1.0 then
    ap.damage_modifier = (ap.damage_modifier or 1.0) * damage_mult
  end
  if range_mult and range_mult ~= 1.0 and ap.range then
    local min_r = (ap.min_range or 0) + 0.1
    ap.range = math.max(min_r, ap.range * range_mult)
    update_beam_deliveries(ap, ap.range)
  end
  if firerate_mult and firerate_mult ~= 1.0 and firerate_mult > 0 and ap.cooldown then
    local new_cooldown = ap.cooldown / firerate_mult
    ap.cooldown = math.max(1, math.floor(new_cooldown + 0.5))
  end
end

-- ============================================================================
-- 6. Recursive Damage Scaling for Ammo & Deliveries
-- ============================================================================
local function scale_damage_effects(node, mult, seen_damage)
  if type(node) ~= "table" then return end
  seen_damage = seen_damage or {}
  if seen_damage[node] then return end
  seen_damage[node] = true

  if node.type == "damage" then
    if type(node.damage) == "table" and type(node.damage.amount) == "number" then
      node.damage.amount = node.damage.amount * mult
      seen_damage[node.damage] = true
    elseif type(node.amount) == "number" then
      node.amount = node.amount * mult
    end
  end

  for _, v in pairs(node) do
    if type(v) == "table" then
      scale_damage_effects(v, mult, seen_damage)
    end
  end
end

local function scan_and_scale_deliveries(node, mult, seen_deliveries, seen_damage, seen_entities)
  if type(node) ~= "table" then return end
  seen_deliveries = seen_deliveries or {}
  seen_damage = seen_damage or {}
  seen_entities = seen_entities or {}
  if seen_deliveries[node] then return end
  seen_deliveries[node] = true

  scale_damage_effects(node, mult, seen_damage)

  -- Check if node has a projectile, stream, or beam reference
  if node.projectile and type(node.projectile) == "string" and data.raw.projectile and data.raw.projectile[node.projectile] then
    local proj = data.raw.projectile[node.projectile]
    if not seen_entities[proj] then
      seen_entities[proj] = true
      if proj.action then scale_damage_effects(proj.action, mult, seen_damage) end
      if proj.final_action then scale_damage_effects(proj.final_action, mult, seen_damage) end
    end
  end

  if node.stream and type(node.stream) == "string" and data.raw.stream and data.raw.stream[node.stream] then
    local strm = data.raw.stream[node.stream]
    if not seen_entities[strm] then
      seen_entities[strm] = true
      if strm.action then scale_damage_effects(strm.action, mult, seen_damage) end
    end
  end

  if node.beam and type(node.beam) == "string" and data.raw.beam and data.raw.beam[node.beam] then
    local bm = data.raw.beam[node.beam]
    if not seen_entities[bm] then
      seen_entities[bm] = true
      if bm.action then scale_damage_effects(bm.action, mult, seen_damage) end
    end
  end

  for _, v in pairs(node) do
    if type(v) == "table" then
      scan_and_scale_deliveries(v, mult, seen_deliveries, seen_damage, seen_entities)
    end
  end
end

-- ============================================================================
-- 7. Deterministic Prototype Search for Overrides
-- ============================================================================
local search_categories = {
  -- Crafting & Production
  "assembling-machine", "furnace", "rocket-silo", "mining-drill", "lab", "beacon",
  -- Energy & Power
  "boiler", "generator", "burner-generator", "reactor", "fusion-reactor", "fusion-generator",
  "solar-panel", "accumulator", "electric-pole", "power-switch",
  -- Logistics & Storage
  "inserter", "roboport", "pump", "offshore-pump", "storage-tank",
  "container", "logistic-container", "infinity-container", "linked-container", "proxy-container",
  "transport-belt", "underground-belt", "splitter", "lane-splitter", "loader", "loader-1x1", "linked-belt",
  "pipe", "pipe-to-ground",
  -- Rails & Transport
  "straight-rail", "curved-rail-a", "curved-rail-b", "half-diagonal-rail", "rail-ramp", "rail-support",
  "elevated-straight-rail", "elevated-curved-rail-a", "elevated-curved-rail-b", "elevated-half-diagonal-rail",
  "train-stop", "rail-signal", "rail-chain-signal", "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon",
  "car", "spider-vehicle",
  -- Defense & Combat
  "turret", "ammo-turret", "electric-turret", "fluid-turret", "artillery-turret",
  "wall", "gate", "radar", "land-mine",
  "gun", "ammo", "projectile", "beam", "stream",
  -- Space Age & Expansion
  "space-platform-hub", "agricultural-tower", "lightning-attractor", "cargo-landing-pad", "cargo-bay",
  "asteroid-collector", "thruster", "crusher", "display-panel", "segmented-unit",
  "spider-unit", "temporary-container",
  -- Circuit & Control
  "constant-combinator", "decider-combinator", "arithmetic-combinator", "selector-combinator", "programmable-speaker",
  -- Characters & Units
  "character", "unit", "unit-spawner"
}

local function find_prototype(name)
  for _, cat in ipairs(search_categories) do
    if data.raw[cat] and data.raw[cat][name] then
      return data.raw[cat][name], cat
    end
  end
  return nil, nil
end

-- ============================================================================
-- 8. DSL Parser for Custom Overrides
-- Format: 'name: key=value, key=value; name2: key=value'
-- ============================================================================
local function parse_and_apply_dsl(dsl_str, tag)
  if not dsl_str or dsl_str == "" then return end

  for entry in string.gmatch(dsl_str, "([^;]+)") do
    local ok, err = pcall(function()
      local name, props_str = string.match(entry, "^%s*([^:]+)%s*:%s*(.+)$")
      if not name or not props_str then
        local trimmed = string.match(entry, "^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then
          log("[Universal Tweaker] Warning (" .. tag .. "): Invalid entry syntax: '" .. trimmed .. "'")
        end
        return
      end

      name = string.match(name, "^%s*(.-)%s*$")
      if not name or name == "" then return end

      local proto, cat = find_prototype(name)
      if not proto then
        log("[Universal Tweaker] Warning (" .. tag .. "): Prototype not found: '" .. name .. "'")
        return
      end

      for k, v in string.gmatch(props_str, "([%a_]+)%s*=%s*([%d%.eE+-]+%w*)") do
        k = string.lower(string.match(k, "^%s*(.-)%s*$"))
        v = string.match(v, "^%s*(.-)%s*$")
        local num = tonumber(v)

        if k == "speed" and num and num >= 0.01 then
          if proto.crafting_speed then proto.crafting_speed = num end
          if proto.mining_speed then proto.mining_speed = num end
          if proto.researching_speed then proto.researching_speed = num end
        elseif k == "energy" then
          local energy_fields = {"energy_usage", "energy_consumption", "consumption", "charging_energy", "energy_per_movement", "energy_per_rotation"}
          local scaled_any = false
          for _, f in ipairs(energy_fields) do
            if proto[f] then
              if num then
                proto[f] = scale_energy(proto[f], num)
              else
                proto[f] = v
              end
              scaled_any = true
            end
          end
          if not scaled_any then
            if proto.energy_source or proto.energy_usage then
              if num then
                proto.energy_usage = scale_energy(proto.energy_usage or "100kW", num)
              else
                proto.energy_usage = v
              end
            end
          end
        elseif k == "pollution" and num then
          scale_pollution(proto, num)
        elseif k == "modules" and num and num >= 0 then
          proto.module_slots = math.floor(num)
          ensure_module_effects(proto)
        elseif k == "prod" and num then
          set_base_productivity(proto, num)
        elseif k == "health" and num and num >= 1 then
          proto.max_health = math.floor(num)
        elseif k == "radius" and num and num >= 0 then
          proto.resource_searching_radius = num
        elseif k == "range" and num and proto.attack_parameters then
          local min_r = (proto.attack_parameters.min_range or 0) + 0.1
          proto.attack_parameters.range = math.max(min_r, num)
          update_beam_deliveries(proto.attack_parameters, proto.attack_parameters.range)
        elseif k == "damage" and num and proto.attack_parameters then
          proto.attack_parameters.damage_modifier = num
        elseif k == "cooldown" and num and proto.attack_parameters then
          proto.attack_parameters.cooldown = math.max(1, math.floor(num))
        elseif k == "firerate" and num and num > 0 and proto.attack_parameters and proto.attack_parameters.cooldown then
          proto.attack_parameters.cooldown = math.max(1, math.floor(proto.attack_parameters.cooldown / num + 0.5))
        else
          log("[Universal Tweaker] Warning (" .. tag .. "): Unknown or invalid key '" .. tostring(k) .. "' on '" .. name .. "'")
        end
      end
    end)
    if not ok then
      log("[Universal Tweaker] Error in DSL parsing (" .. tag .. "): " .. tostring(err))
    end
  end
end

-- ============================================================================
-- 9. Apply Global Building Settings
-- ============================================================================
local crafting_speed_mult = get_setting("ut-global-crafting-speed", 1.0)
local mining_speed_mult   = get_setting("ut-global-mining-speed", 1.0)
local mining_radius_bonus = get_setting("ut-global-mining-radius", 0)
local lab_speed_mult      = get_setting("ut-global-lab-speed", 1.0)
local energy_mult         = get_setting("ut-global-energy-multiplier", 1.0)
local pollution_mult      = get_setting("ut-global-pollution-multiplier", 1.0)
local extra_module_slots  = get_setting("ut-global-extra-module-slots", 0)
local base_prod_bonus     = get_setting("ut-global-base-productivity", 0.0)
local building_health_mult= get_setting("ut-global-building-health", 1.0)

local building_categories = {
  "assembling-machine", "furnace", "rocket-silo", "mining-drill", "lab",
  "boiler", "generator", "burner-generator", "reactor", "fusion-reactor", "fusion-generator",
  "solar-panel", "accumulator", "electric-pole", "pipe", "pipe-to-ground",
  "pump", "offshore-pump", "storage-tank", "container", "logistic-container",
  "infinity-container", "linked-container", "proxy-container",
  "transport-belt", "underground-belt", "splitter", "lane-splitter", "loader", "loader-1x1", "linked-belt",
  "inserter", "radar", "beacon", "roboport", "wall", "gate",
  "turret", "ammo-turret", "electric-turret", "fluid-turret", "artillery-turret",
  "straight-rail", "curved-rail-a", "curved-rail-b", "half-diagonal-rail", "rail-ramp", "rail-support",
  "elevated-straight-rail", "elevated-curved-rail-a", "elevated-curved-rail-b", "elevated-half-diagonal-rail",
  "train-stop", "rail-signal", "rail-chain-signal",
  "space-platform-hub", "agricultural-tower", "lightning-attractor", "cargo-landing-pad", "cargo-bay",
  "asteroid-collector", "thruster", "display-panel",
  "constant-combinator", "decider-combinator", "arithmetic-combinator", "selector-combinator",
  "power-switch", "programmable-speaker"
}

-- 9a. Crafting speed & Base prod on assembling machines, furnaces, rocket silos, agricultural towers
local crafting_types = {"assembling-machine", "furnace", "rocket-silo", "agricultural-tower"}
for _, ctype in ipairs(crafting_types) do
  if data.raw[ctype] then
    for _, machine in pairs(data.raw[ctype]) do
      if crafting_speed_mult ~= 1.0 and machine.crafting_speed then
        machine.crafting_speed = machine.crafting_speed * crafting_speed_mult
      end
      if base_prod_bonus > 0 then
        add_base_productivity(machine, base_prod_bonus)
      end
      if extra_module_slots > 0 then
        machine.module_slots = (machine.module_slots or 0) + extra_module_slots
        ensure_module_effects(machine)
      end
    end
  end
end

-- 9b. Mining speed, radius, base prod, and module slots on mining drills
if data.raw["mining-drill"] then
  for _, drill in pairs(data.raw["mining-drill"]) do
    if mining_speed_mult ~= 1.0 and drill.mining_speed then
      drill.mining_speed = drill.mining_speed * mining_speed_mult
    end
    if mining_radius_bonus > 0 and drill.resource_searching_radius then
      drill.resource_searching_radius = drill.resource_searching_radius + mining_radius_bonus
    end
    if base_prod_bonus > 0 then
      add_base_productivity(drill, base_prod_bonus)
    end
    if extra_module_slots > 0 then
      drill.module_slots = (drill.module_slots or 0) + extra_module_slots
      ensure_module_effects(drill)
    end
  end
end

-- 9c. Lab researching speed, base prod, and module slots
if data.raw["lab"] then
  for _, lab in pairs(data.raw["lab"]) do
    if lab_speed_mult ~= 1.0 and lab.researching_speed then
      lab.researching_speed = lab.researching_speed * lab_speed_mult
    end
    if base_prod_bonus > 0 then
      add_base_productivity(lab, base_prod_bonus)
    end
    if extra_module_slots > 0 then
      lab.module_slots = (lab.module_slots or 0) + extra_module_slots
      ensure_module_effects(lab)
    end
  end
end

-- 9d. Beacons module slots
if data.raw["beacon"] and extra_module_slots > 0 then
  for _, beacon in pairs(data.raw["beacon"]) do
    beacon.module_slots = (beacon.module_slots or 0) + extra_module_slots
    ensure_module_effects(beacon)
  end
end

-- 9e. Global Energy Multiplier, Pollution Multiplier, and Building Health
for _, cat in ipairs(building_categories) do
  if data.raw[cat] then
    for _, entity in pairs(data.raw[cat]) do
      -- Energy (scales consumption/draw only; power production is preserved)
      if energy_mult ~= 1.0 then
        if entity.energy_usage then
          entity.energy_usage = scale_energy(entity.energy_usage, energy_mult)
        end
        if entity.energy_consumption then
          entity.energy_consumption = scale_energy(entity.energy_consumption, energy_mult)
        end
        if entity.consumption then
          entity.consumption = scale_energy(entity.consumption, energy_mult)
        end
        if entity.charging_energy then
          entity.charging_energy = scale_energy(entity.charging_energy, energy_mult)
        end
        if entity.energy_per_movement then
          entity.energy_per_movement = scale_energy(entity.energy_per_movement, energy_mult)
        end
        if entity.energy_per_rotation then
          entity.energy_per_rotation = scale_energy(entity.energy_per_rotation, energy_mult)
        end
        if entity.heating_energy then
          entity.heating_energy = scale_energy(entity.heating_energy, energy_mult)
        end
        if entity.crane_energy_usage then
          entity.crane_energy_usage = scale_energy(entity.crane_energy_usage, energy_mult)
        end
        if entity.energy_source and entity.energy_source.drain then
          entity.energy_source.drain = scale_energy(entity.energy_source.drain, energy_mult)
        end
      end
      -- Pollution
      if pollution_mult ~= 1.0 then
        scale_pollution(entity, pollution_mult)
      end
      -- Health
      if building_health_mult ~= 1.0 and entity.max_health then
        entity.max_health = math.max(1, math.floor(entity.max_health * building_health_mult + 0.5))
      end
    end
  end
end

-- ============================================================================
-- 10. Apply Global Weapon & Combat Settings
-- ============================================================================
local gun_damage_mult    = get_setting("ut-global-gun-damage", 1.0)
local gun_range_mult     = get_setting("ut-global-gun-range", 1.0)
local gun_firerate_mult  = get_setting("ut-global-gun-firerate", 1.0)
local turret_damage_mult = get_setting("ut-global-turret-damage", 1.0)
local turret_range_mult  = get_setting("ut-global-turret-range", 1.0)
local turret_firerate_mult=get_setting("ut-global-turret-firerate", 1.0)
local ammo_damage_mult   = get_setting("ut-global-ammo-damage", 1.0)

-- Guns
if data.raw["gun"] then
  for _, gun in pairs(data.raw["gun"]) do
    scale_attack_parameters(gun.attack_parameters, gun_damage_mult, gun_range_mult, gun_firerate_mult)
  end
end

-- Turrets
local turret_types = {"ammo-turret", "electric-turret", "fluid-turret", "turret", "artillery-turret"}
for _, ttype in ipairs(turret_types) do
  if data.raw[ttype] then
    for _, turret in pairs(data.raw[ttype]) do
      scale_attack_parameters(turret.attack_parameters, turret_damage_mult, turret_range_mult, turret_firerate_mult)
    end
  end
end

-- Ammo
if ammo_damage_mult ~= 1.0 and data.raw["ammo"] then
  local seen_deliveries = {}
  local seen_damage = {}
  local seen_entities = {}
  for _, ammo in pairs(data.raw["ammo"]) do
    if ammo.ammo_type then
      scan_and_scale_deliveries(ammo.ammo_type, ammo_damage_mult, seen_deliveries, seen_damage, seen_entities)
    end
  end
end

-- ============================================================================
-- 11. Dedicated Overrides
-- ============================================================================
local ov_assembler3_speed = get_setting("ut-override-assembler3-speed", 1.25)
local ov_assembler3_modules = get_setting("ut-override-assembler3-modules", 4)
local ov_drill_speed = get_setting("ut-override-electric-drill-speed", 0.5)
local ov_laser_range = get_setting("ut-override-laser-turret-range", 24.0)
local ov_laser_damage = get_setting("ut-override-laser-turret-damage", 1.0)

if data.raw["assembling-machine"] and data.raw["assembling-machine"]["assembling-machine-3"] then
  local as3 = data.raw["assembling-machine"]["assembling-machine-3"]
  if ov_assembler3_speed ~= 1.25 then
    as3.crafting_speed = ov_assembler3_speed
  end
  if ov_assembler3_modules ~= 4 then
    as3.module_slots = ov_assembler3_modules
    ensure_module_effects(as3)
  end
end

if data.raw["mining-drill"] and data.raw["mining-drill"]["electric-mining-drill"] then
  local drill = data.raw["mining-drill"]["electric-mining-drill"]
  if ov_drill_speed ~= 0.5 then
    drill.mining_speed = ov_drill_speed
  end
end

if data.raw["electric-turret"] and data.raw["electric-turret"]["laser-turret"] then
  local laser = data.raw["electric-turret"]["laser-turret"]
  if laser.attack_parameters then
    if ov_laser_range ~= 24.0 then
      laser.attack_parameters.range = math.max((laser.attack_parameters.min_range or 0) + 0.1, ov_laser_range)
      update_beam_deliveries(laser.attack_parameters, laser.attack_parameters.range)
    end
    if ov_laser_damage ~= 1.0 then
      laser.attack_parameters.damage_modifier = ov_laser_damage
    end
  end
end

-- ============================================================================
-- 12. Custom Overrides via DSL
-- ============================================================================
local custom_bld = get_setting("ut-custom-building-overrides", "")
if custom_bld and custom_bld ~= "" then
  parse_and_apply_dsl(custom_bld, "Buildings")
end

local custom_wpn = get_setting("ut-custom-weapon-overrides", "")
if custom_wpn and custom_wpn ~= "" then
  parse_and_apply_dsl(custom_wpn, "Weapons")
end
