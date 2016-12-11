-- Bounds for expected behaviour: 0.0 > x > -1.0
-- Above 0: becomes FastKey
-- Below -1.0: inverts movement

SLOWNESS = -0.5

slowed = false

script.on_event("slowkey-slow", function(event)
    local player = game.players[event.player_index]
    if (not player.character) or (not player.connected) then
        return
    end
    if not slowed then
        old_speed = player.character_running_speed_modifier
        player.character.character_running_speed_modifier = SLOWNESS
    else
        player.character.character_running_speed_modifier = old_speed
    end
    slowed = not slowed
end)
