-- Bounds for expected behaviour: 0.0 > x > -1.0
-- Above 0: becomes FastKey
-- Below -1.0: inverts movement
-- 0 is factorio default modifier when creating player.
-- Other mods can set this either higher or lower

--Default modifier
local MODIFIER = -0.5
local DEBUG = false

local function debug(string)
  if DEBUG then
    game.print(string)
  end
end

--Return a valid player from index, string, table
local function get_valid_player(player)
  player = player or game.player --If player is blank, see if there is a game.player (console user)
  if type(player) == "number" or type(player) == "string" then --If an index or name is passed.
    player = game.players[player]
  end
  if player and type(player) == "table" and player.valid then --Do we have a valid player now?
    return player --Return the player
  else
    return nil
  end
end

--Create a small text caption on our character when we are slowed.
local function info_gui(player, slowed)
  if player.gui.center["slowkey"] then player.gui.center["slowkey"].destroy() end
  if slowed then
    local gui = player.gui.center.add{type="label", name="slowkey", caption=" (SLOW) ", direction = "vertical"}
    gui.style.minimal_width=32
  end
end

--Create the global if not exists, Doing this here will have no noticeable impact on performance.
local function get_or_create_global(player_index)
  global.player_data = global.player_data or {}
  global.player_data[player_index] = global.player_data[player_index] or {modifier = MODIFIER}
  return global.player_data[player_index] --Return the table all in one fell swoop
end

--The meat and potatoes
script.on_event("slowkey-slow",
  function(event)
    local pdata = get_or_create_global(event.player_index) --Create local reference to players global mod data
    local player = game.players[event.player_index] --Create local reference to the player

    --Determine if player is ready
    if player and player.controller_type == defines.controllers.character then
      local cur_modifier = player.character_running_speed_modifier --Let's shorten this up a bit
      if pdata.last_modifier then --We are slowed down, let's speed back up.
        local change = ((pdata.saved_modifier == cur_modifier) and pdata.last_modifier) or cur_modifier
        debug("SlowKey disable: Change="..change.." cur="..cur_modifier.." last="..pdata.last_modifier)
        player.character_running_speed_modifier = change
        info_gui(player, false)
        --Free up unneeded variables
        pdata.saved_modifier, pdata.last_modifier = nil, nil
      else --We are at normal speed, let's slow down
        pdata.last_modifier = cur_modifier --Save a copy of the players current modifier in case it gets changed.
        pdata.saved_modifier = pdata.modifier --Save a copy of the slow modifier in case we change it.
        player.character_running_speed_modifier = pdata.modifier
        info_gui(player, true)
      end
    end
  end
)

local interface = {}
--Change the modifier amount directly from the command line
interface.change_modifier = function (value, player)
  value = value or MODIFIER
  player = get_valid_player(player)
  if player then
    local pdata = get_or_create_global(player.index)
    local cur_modifier = ((player.controller_type == defines.controllers.character) and player.character_running_speed_modifier) or 0
    if value <= cur_modifier and value > -1 then
      pdata.modifier = value
      player.print("SlowKey: New default slow modifier set to "..value)
      return value
    else
      player.print("SlowKey: Value("..value..") must be greater than current_modifier("..cur_modifier..") and less than -l")
    end
  end
end

--Change the modifier for all players
interface.change_modifier_for_all = function(value)
  value = value or MODIFIER
  for _, player in pairs(game.players) do
    interface.change_modifier(value, player)
  end
end

--Return the current modifier
interface.read_modifier = function(player)
  player = get_valid_player(player)
  if player then
    local pdata = get_or_create_global(player.index)
    player.print("SlowKey: Current modifier is "..pdata.modifier)
    return pdata.modifier
  end
end

--Print the global table
interface.print_global = function()
  local print_str = "SlowKey: Default Modifier = "..MODIFIER.."\nglobal="..serpent.block(global, {comment=false})
  game.print(print_str)
  game.write_file("logs/slow-key/global.txt", print_str, false)
end

--Add Our interfaces to the game
remote.add_interface("slowkey", interface)
