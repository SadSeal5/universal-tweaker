-- Universal Entity & Weapon Tweaker - control.lua
-- Factorio 2.1 Mod

local function get_entity_prototypes()
  if prototypes and prototypes.entity then
    return prototypes.entity
  elseif game and game.entity_prototypes then
    return game.entity_prototypes
  end
  return {}
end

-- ============================================================================
-- 1. /tweak-inspect Command
-- ============================================================================
commands.add_command("tweak-inspect", {"command-help.tweak-inspect"}, function(cmd)
  local player = cmd.player_index and game.get_player(cmd.player_index)
  if not player then return end

  local entity = player.selected
  if not entity or not entity.valid then
    player.print("[color=orange][Universal Tweaker][/color] No entity selected. Hover your mouse cursor over an entity and run /tweak-inspect.")
    return
  end

  local p = entity.prototype
  if not p then return end

  player.print("[color=orange][Universal Tweaker] Inspecting:[/color] [color=white]" .. tostring(entity.name) .. "[/color] [color=gray](" .. tostring(entity.type) .. ")[/color]")

  -- Health
  pcall(function()
    local max_h = entity.max_health
    if max_h and max_h > 0 then
      local cur_h = entity.health or max_h
      player.print("  [color=yellow]Max Health:[/color] " .. tostring(math.floor(max_h)) .. " [color=gray](Current: " .. tostring(math.floor(cur_h)) .. ")[/color]")
    end
  end)

  -- Crafting Speed
  pcall(function()
    local spd
    if p.get_crafting_speed and entity.quality then
      spd = p:get_crafting_speed(entity.quality)
    elseif entity.crafting_speed then
      spd = entity.crafting_speed
    elseif p.crafting_speed then
      spd = p.crafting_speed
    end
    if spd and spd > 0 then
      player.print("  [color=yellow]Crafting Speed:[/color] " .. tostring(spd))
    end
  end)

  -- Mining Speed
  if entity.type == "mining-drill" or entity.type == "character" then
    pcall(function()
      local mspd
      if p.get_mining_speed and entity.quality then
        mspd = p:get_mining_speed(entity.quality)
      elseif p.mining_speed then
        mspd = p.mining_speed
      end
      if mspd and mspd > 0 then
        player.print("  [color=yellow]Mining Speed:[/color] " .. tostring(mspd))
      end
    end)
  end

  -- Mining Search Radius
  if entity.type == "mining-drill" then
    pcall(function()
      local rad = p.resource_searching_radius
      if rad and rad > 0 then
        player.print("  [color=yellow]Mining Search Radius:[/color] " .. tostring(rad))
      end
    end)
  end

  -- Researching Speed
  if entity.type == "lab" then
    pcall(function()
      local rspd
      if p.get_researching_speed and entity.quality then
        rspd = p:get_researching_speed(entity.quality)
      elseif p.researching_speed then
        rspd = p.researching_speed
      end
      if rspd and rspd > 0 then
        player.print("  [color=yellow]Researching Speed:[/color] " .. tostring(rspd))
      end
    end)
  end

  -- Base Productivity
  pcall(function()
    local prod
    if p.effect_receiver and p.effect_receiver.base_effect and p.effect_receiver.base_effect.productivity then
      prod = p.effect_receiver.base_effect.productivity
    elseif entity.productivity_bonus and entity.productivity_bonus > 0 then
      prod = entity.productivity_bonus
    elseif p.base_productivity and p.base_productivity > 0 then
      prod = p.base_productivity
    end
    if prod and prod > 0 then
      player.print("  [color=yellow]Base Productivity:[/color] +" .. string.format("%.1f%%", prod * 100))
    end
  end)

  -- Energy Usage
  pcall(function()
    local nrg
    if p.get_max_energy_usage and entity.quality then
      nrg = p:get_max_energy_usage(entity.quality)
    elseif p.max_energy_usage then
      nrg = p.max_energy_usage
    elseif p.energy_usage then
      nrg = p.energy_usage
    end
    if nrg and nrg > 0 then
      local nrg_str
      if type(nrg) == "number" then
        local watts = nrg * 60
        if watts >= 1e6 then
          nrg_str = string.format("%.2f MW", watts / 1e6)
        elseif watts >= 1e3 then
          nrg_str = string.format("%.2f kW", watts / 1e3)
        else
          nrg_str = string.format("%.2f W", watts)
        end
      else
        nrg_str = tostring(nrg)
      end
      player.print("  [color=yellow]Max Energy Usage:[/color] " .. nrg_str)
    end
  end)

  -- Passive Drain
  pcall(function()
    if p.electric_energy_source_prototype and p.electric_energy_source_prototype.drain then
      local drn = p.electric_energy_source_prototype.drain
      if drn and drn > 0 then
        local drn_str
        if type(drn) == "number" then
          local watts = drn * 60
          if watts >= 1e6 then
            drn_str = string.format("%.2f MW", watts / 1e6)
          elseif watts >= 1e3 then
            drn_str = string.format("%.2f kW", watts / 1e3)
          else
            drn_str = string.format("%.2f W", watts)
          end
        else
          drn_str = tostring(drn)
        end
        player.print("  [color=yellow]Passive Drain:[/color] " .. drn_str)
      end
    end
  end)

  -- Module Slots
  pcall(function()
    local slots
    if entity.get_module_inventory then
      local inv = entity.get_module_inventory()
      if inv and inv.valid then
        slots = #inv
      end
    end
    if not slots then
      if p.get_module_inventory_size and entity.quality then
        slots = p:get_module_inventory_size(entity.quality)
      elseif p.module_inventory_size then
        slots = p.module_inventory_size
      end
    end
    if slots and slots > 0 then
      player.print("  [color=yellow]Module Slots:[/color] " .. tostring(slots))
    end
  end)

  -- Attack parameters (Turrets / Combat)
  pcall(function()
    if p.attack_parameters then
      local ap = p.attack_parameters
      local range_str = ap.range and tostring(ap.range) or "N/A"
      local cooldown_str = ap.cooldown and tostring(ap.cooldown) or "N/A"
      local dmg_mod_str = ap.damage_modifier and tostring(ap.damage_modifier) or "1.0"
      player.print("  [color=yellow]Combat:[/color] Range: " .. range_str .. " | Cooldown: " .. cooldown_str .. " ticks | Damage Mod: " .. dmg_mod_str)
    end
  end)
end)

-- ============================================================================
-- 2. /tweak-help Command
-- ============================================================================
commands.add_command("tweak-help", {"command-help.tweak-help"}, function(cmd)
  local player = cmd.player_index and game.get_player(cmd.player_index)
  local function out(msg)
    if player then
      player.print(msg)
    elseif rcon then
      pcall(rcon.print, msg)
    else
      print(msg)
    end
  end

  out("[color=orange]=== [Universal Tweaker Guide] ===[/color]")
  out("[color=yellow]Custom Overrides DSL Syntax:[/color]")
  out("  [color=white]name: key=value, key=value; name2: key=value[/color]")
  out("[color=yellow]Supported Keys:[/color]")
  out("  [color=cyan]speed[/color]: Crafting / mining / researching speed")
  out("  [color=cyan]energy[/color]: Multiplier (e.g. 0.5) or exact value (e.g. 150kW)")
  out("  [color=cyan]pollution[/color]: Pollution multiplier (e.g. 0.5 or 0)")
  out("  [color=cyan]modules[/color]: Number of module slots (e.g. 6)")
  out("  [color=cyan]prod[/color]: Base productivity bonus (e.g. 0.2 for +20%)")
  out("  [color=cyan]health[/color]: Maximum health (e.g. 2000)")
  out("  [color=cyan]radius[/color]: Mining drill resource search radius (e.g. 5)")
  out("  [color=cyan]range[/color]: Turret or weapon attack range (e.g. 35)")
  out("  [color=cyan]damage[/color]: Turret or weapon damage modifier (e.g. 2.5)")
  out("  [color=cyan]firerate[/color]: Firerate multiplier (e.g. 2.0 for 2x faster)")
  out("  [color=cyan]cooldown[/color]: Attack cooldown in ticks (e.g. 10)")
  out("[color=yellow]Preset Examples:[/color]")
  out("  [color=gray]Buildings:[/color] assembling-machine-3: speed=5, modules=8, prod=0.2; electric-mining-drill: speed=2, radius=5")
  out("  [color=gray]Weapons:[/color] laser-turret: damage=3, range=40; gun-turret: firerate=2, range=25")
  out("[color=yellow]Runtime Commands:[/color]")
  out("  [color=green]/tweak-inspect[/color]: Inspect stats of entity under mouse cursor.")
  out("  [color=green]/tweak-bonus <category> <value>[/color]: Set live force bonuses (crafting, mining, lab, turret).")
  out("[color=gray]Note: Startup settings require game restart/reload; /tweak-bonus works immediately in-game.[/color]")
end)

-- ============================================================================
-- 3. /tweak-bonus Command
-- ============================================================================
commands.add_command("tweak-bonus", {"command-help.tweak-bonus"}, function(cmd)
  local player = cmd.player_index and game.get_player(cmd.player_index)
  if player and not player.admin then
    player.print("[color=red][Universal Tweaker] Only administrators can modify force bonuses.[/color]")
    return
  end

  local force = player and player.force or (game and game.forces["player"])
  if not force then return end

  local function out(msg)
    if player then
      player.print(msg)
    elseif rcon then
      pcall(rcon.print, msg)
    else
      print(msg)
    end
  end

  local param = cmd.parameter
  if not param or param == "" then
    out("[color=orange][Universal Tweaker] Live Force Modifiers for force: " .. force.name .. "[/color]")
    out("  [color=yellow]Crafting Speed Bonus:[/color] " .. string.format("+%.1f%%", (force.manual_crafting_speed_modifier or 0) * 100))
    out("  [color=yellow]Mining Speed Bonus:[/color] " .. string.format("+%.1f%%", (force.manual_mining_speed_modifier or 0) * 100))
    out("  [color=yellow]Lab Speed Bonus:[/color] " .. string.format("+%.1f%%", (force.laboratory_speed_modifier or 0) * 100))
    out("[color=gray]Usage: /tweak-bonus <crafting|mining|lab|turret> <bonus_value>[/color]")
    out("[color=gray]Example: /tweak-bonus crafting 2.0   (sets +200% manual crafting speed)[/color]")
    return
  end

  local cat, val_str = string.match(param, "^%s*([%a_-]+)%s+([%d%.eE+-]+)%s*$")
  if not cat or not val_str then
    out("[color=red][Universal Tweaker] Invalid format. Use: /tweak-bonus <crafting|mining|lab|turret> <value>[/color]")
    return
  end

  local val = tonumber(val_str)
  if not val then
    out("[color=red][Universal Tweaker] Value must be a valid number.[/color]")
    return
  end

  cat = string.lower(cat)
  if cat == "crafting" then
    local ok = pcall(function() force.manual_crafting_speed_modifier = val end)
    if ok then
      out("[color=green][Universal Tweaker] Set manual crafting speed bonus to +" .. tostring(val * 100) .. "%[/color]")
    else
      out("[color=red][Universal Tweaker] Failed to set manual crafting speed bonus.[/color]")
    end
  elseif cat == "mining" then
    local ok = pcall(function() force.manual_mining_speed_modifier = val end)
    if ok then
      out("[color=green][Universal Tweaker] Set manual mining speed bonus to +" .. tostring(val * 100) .. "%[/color]")
    else
      out("[color=red][Universal Tweaker] Failed to set manual mining speed bonus.[/color]")
    end
  elseif cat == "lab" then
    local ok = pcall(function() force.laboratory_speed_modifier = val end)
    if ok then
      out("[color=green][Universal Tweaker] Set lab research speed bonus to +" .. tostring(val * 100) .. "%[/color]")
    else
      out("[color=red][Universal Tweaker] Failed to set lab research speed bonus.[/color]")
    end
  elseif cat == "turret" then
    local count = 0
    local turret_types = {["ammo-turret"] = true, ["electric-turret"] = true, ["fluid-turret"] = true, ["turret"] = true, ["artillery-turret"] = true}
    local entity_protos = get_entity_prototypes()
    for name, proto in pairs(entity_protos) do
      if turret_types[proto.type] then
        pcall(function()
          force.set_turret_attack_modifier(name, val)
          count = count + 1
        end)
      end
    end
    out("[color=green][Universal Tweaker] Updated attack modifier for " .. tostring(count) .. " turret types to +" .. tostring(val * 100) .. "%[/color]")
  else
    out("[color=red][Universal Tweaker] Unknown category '" .. cat .. "'. Choose from: crafting, mining, lab, turret.[/color]")
  end
end)
