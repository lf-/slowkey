-- Bounds for expected behaviour: 0.0 > x > -1.0
-- Above 0: becomes FastKey (0 is default modifier when creating player unless changed by mods)
-- Below -1.0: inverts movement

--Default modifier
local MODIFIER = -0.5
local DEBUG = false

local function debug(string)
  if DEBUG then
    game.print(string)
  end
end

--return a valid player from index, string, table
local function get_valid_player(player)
  player=player or game.player -- player is blank, see if there is a game.player (console user)
  if type(player)=="number" or type(player) == "string" then --if an index or name is passed.
    player=game.players[player]
  end
  if player and player.valid then --Do we have a valid player now?
    return player --return the player
  else
    return nil
  end
end

--Create a small text caption on our character when we are slowed.
local function info_gui(player, slowed)
  if player.gui.center["slow-key"] then player.gui.center["slow-key"].destroy() end
  if slowed then
    local gui = player.gui.center.add{type="label", name="slow-key", caption=" (SLOW) ", direction = "vertical"}
    gui.style.minimal_width=32
  end
end

--create the global if not exists, Doing this here will have no noticeable impact on performance.
local function get_or_create_global(player_index)
  if not global.player_data then global.player_data = {} end
  if not global.player_data[player_index] then global.player_data[player_index] = {modifier = MODIFIER, slowed=false} end
  return global.player_data[player_index] --return the table all in one fell swoop
end

--The meat and potatoes
script.on_event("slowkey-slow",
  function(event)
    local pdata = get_or_create_global(event.player_index) --create local reference to players global data we need
    local player = game.players[event.player_index] --create local reference to the player
    --Determine ready to do stuff player
    if player.connected and player.character and player.controller_type == defines.controllers.character then

      local cur_modifier = player.character.character_running_speed_modifier -- Lets shorten this up a bit :)
      if pdata.slowed then -- We are slowed down, lets speed back up.
        local change = (pdata.difference + cur_modifier == pdata.last_modifier and pdata.difference) or (cur_modifier + math.abs(pdata.saved_modifier))
        debug("changing speed modifier to "..cur_modifier + change.. " cur="..cur_modifier.." old="..pdata.last_modifier.." dif="..pdata.difference)
        player.character.character_running_speed_modifier = cur_modifier + change
        info_gui(player, false)
        pdata.slowed=false
        --free up uneeded variables
        pdata.difference, pdata.saved_modifier, pdata.last_modifier = nil, nil, nil
      else -- We are at normal speed, lets slow down
        pdata.last_modifier = cur_modifier -- Save a copy of the players current modifier in case it gets changed.
        pdata.saved_modifier = pdata.modifier -- Save a copy of the slow modifier in case we change it.
        pdata.difference = cur_modifier - pdata.modifier -- get the difference in case players modifier changes some other way.
        pdata.slowed = true
        debug("Slowing speed to "..pdata.modifier.. " from="..cur_modifier.." diff="..pdata.difference)
        player.character.character_running_speed_modifier = pdata.modifier
        info_gui(player, true)
      end

    end
  end
)

local interface = {}
--Change the modifier amount directly from the command line!
interface.change_slow_key_modifier = function (value, player)
  value = value or MODIFIER
  player = get_valid_player(player)
  if player then
    local pdata = get_or_create_global(player.index)
    local cur_modifier = (player.connected and player.character and player.character.character_running_speed_modifier) or 0
    if value <= cur_modifier and value > -1 then
      pdata.modifier = value
      game.player.print("slow-key: New default slow modifier set to "..value)
      return value
    else
      game.player.print("slow-key: Value "..value.." must be greater than current_modifier:"..cur_modifier.." and less than -l")
    end
  end
end
--Read the current modifier
interface.read_slow_key_modifier = function(player)
  player = get_valid_player(player)
  if player then
    local pdata = get_or_create_global(player.index)
    player.print("slow-key: Current modifier is "..pdata.modifier)
    return pdata.modifier
  end
end
--Add Our interface to the game
remote.add_interface("slow-key", interface)
