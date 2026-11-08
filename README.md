# Universal Entity & Weapon Tweaker (universal-tweaker)
**Factorio 2.1 Mod**
**Author:** SadSeal5

## Overview
Universal Entity & Weapon Tweaker gives players and server administrators complete control over Factorio 2.1 building speeds, energy consumption, pollution, module slots, innate productivity bonuses, building health, weapon damage, weapon ranges, turret firerates, and ammo damage.

Changes can be configured:
1. **Globally** via standard Startup Settings sliders.
2. **Dedicated Sliders** for popular entities (Assembler 3, Electric Mining Drill, Laser Turret).
3. **Individually via DSL** (`ut-custom-building-overrides` and `ut-custom-weapon-overrides`).

---

## Startup Settings

### Global Buildings
- **Global Crafting Speed Multiplier** (`ut-global-crafting-speed`): Scales assembling machines, furnaces, rocket silos (0.01 - 100x).
- **Global Mining Speed Multiplier** (`ut-global-mining-speed`): Scales all mining drills (0.01 - 100x).
- **Global Extra Mining Radius** (`ut-global-mining-radius`): Expands mining drill search radius (+0 to +20 tiles).
- **Global Lab Research Speed** (`ut-global-lab-speed`): Scales science labs (0.01 - 100x).
- **Global Energy Multiplier** (`ut-global-energy-multiplier`): Multiplies building power consumption and passive drain (0.0 for free power).
- **Global Pollution Multiplier** (`ut-global-pollution-multiplier`): Scales pollution emissions (0.0 to disable pollution).
- **Global Extra Module Slots** (`ut-global-extra-module-slots`): Adds bonus module slots to assemblers, furnaces, drills, labs, beacons (+0 to +20).
- **Global Base Productivity Bonus** (`ut-global-base-productivity`): Grants innate productivity bonus without modules (e.g., 0.2 = +20%).
- **Global Building Health** (`ut-global-building-health`): Scales maximum HP of all factory structures and walls (0.1 - 50x).

### Global Weapons & Combat
- **Global Gun Damage Multiplier** (`ut-global-gun-damage`): Handheld weapon damage modifier.
- **Global Gun Range Multiplier** (`ut-global-gun-range`): Handheld weapon attack range.
- **Global Gun Firerate Multiplier** (`ut-global-gun-firerate`): Handheld firing speed (reduces attack cooldown).
- **Global Turret Damage Multiplier** (`ut-global-turret-damage`): Turret damage modifier (gun, laser, flamethrower, artillery).
- **Global Turret Range Multiplier** (`ut-global-turret-range`): Turret attack reach.
- **Global Turret Firerate Multiplier** (`ut-global-turret-firerate`): Turret firing speed.
- **Global Ammo Damage Multiplier** (`ut-global-ammo-damage`): Scales damage of ammunition, projectiles, rockets, streams, and beams.

---

## Custom Overrides DSL

In `ut-custom-building-overrides` and `ut-custom-weapon-overrides`, enter semicolon-separated rules:
```
name: key=value, key=value; name2: key=value
```

### Supported Keys:
| Key | Description | Example |
|---|---|---|
| `speed` | Crafting / mining / lab speed | `speed=2.5` |
| `energy` | Energy consumption multiplier or value | `energy=0.5` or `energy=100kW` |
| `pollution` | Pollution emissions multiplier | `pollution=0.1` |
| `modules` | Exact number of module slots | `modules=6` |
| `prod` | Innate base productivity bonus | `prod=0.2` (+20%) |
| `health` | Maximum health | `health=1500` |
| `radius` | Mining drill resource search radius | `radius=5` |
| `range` | Weapon or turret attack range | `range=35` |
| `damage` | Attack damage modifier | `damage=3.0` |
| `firerate`| Attack firerate multiplier | `firerate=2.0` |
| `cooldown`| Attack cooldown in ticks | `cooldown=12` |

### Example DSL String:
```
assembling-machine-3: speed=5, modules=8, prod=0.2; electric-mining-drill: speed=2, radius=5; laser-turret: damage=3, range=40
```

---

## In-Game Console Commands

- `/tweak-inspect`: Inspects detailed stats of the entity under your mouse cursor.
- `/tweak-help`: Prints the DSL syntax guide and preset examples.
- `/tweak-bonus <category> <value>`: Instantly modifies live force bonuses for testing (categories: `crafting`, `mining`, `lab`, `turret`).
