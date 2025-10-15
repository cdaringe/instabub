-- instabub mod for SM64CoopDX
-- Press D-pad Up to instantly enter bubble
-- While in bubble: D-pad Down to warp to next player

-- Speed change increments
local SPEED_INCREMENT = 0.3
local SPEED_DECREMENT = 0.3
local MIN_SPEED_MULTIPLIER = 1.0
local MAX_SPEED_MULTIPLIER = 1.8

-- Current speed multiplier for bubble movement
local bubbleSpeedMultiplier = MIN_SPEED_MULTIPLIER

-- Track previous bubble state to detect when we exit bubble
local wasBubbled = false

-- Track which player we last warped to
local lastWarpedPlayerIndex = 0

-- Mario's height for offset
local MARIO_HEIGHT = 160

-- Find the next connected and alive player after lastWarpedPlayerIndex
local function get_next_player()
    -- Start searching from the player after our last warp target
    for i = lastWarpedPlayerIndex + 1, MAX_PLAYERS - 1 do
        local np = gNetworkPlayers[i]
        local ms = gMarioStates[i]
        -- Only warp to connected players who are not bubbled (alive)
        if np.connected and ms.action ~= ACT_BUBBLED then
            return i
        end
    end

    -- Wrap around: search from player 1 to lastWarpedPlayerIndex
    for i = 1, lastWarpedPlayerIndex do
        local np = gNetworkPlayers[i]
        local ms = gMarioStates[i]
        if np.connected and ms.action ~= ACT_BUBBLED then
            return i
        end
    end

    return nil
end


-- Handle button presses for local player
function mario_update(m)
    -- Only process for local player
    if m.playerIndex ~= 0 then return end

    -- Check if D-pad Up was just pressed - enter bubble
    if (m.controller.buttonPressed & U_JPAD) ~= 0 then
        if m.action ~= ACT_BUBBLED then
            set_mario_action(m, ACT_BUBBLED, 0)
        end
    end

    -- Only process bubble controls if already in bubble
    if m.action == ACT_BUBBLED then
        -- D-pad Right: increase speed multiplier
        if (m.controller.buttonPressed & R_JPAD) ~= 0 then
            bubbleSpeedMultiplier = bubbleSpeedMultiplier + SPEED_INCREMENT
            if bubbleSpeedMultiplier > MAX_SPEED_MULTIPLIER then
                bubbleSpeedMultiplier = MAX_SPEED_MULTIPLIER
            end
        end

        -- D-pad Left: decrease speed multiplier
        if (m.controller.buttonPressed & L_JPAD) ~= 0 then
            bubbleSpeedMultiplier = bubbleSpeedMultiplier - SPEED_DECREMENT
            if bubbleSpeedMultiplier < MIN_SPEED_MULTIPLIER then
                bubbleSpeedMultiplier = MIN_SPEED_MULTIPLIER
            end
        end

        -- D-pad Down: warp to next player
        if (m.controller.buttonPressed & D_JPAD) ~= 0 then
            local nextPlayerIndex = get_next_player()
            if nextPlayerIndex ~= nil then
                local targetPlayer = gMarioStates[nextPlayerIndex]
                -- Teleport to one Mario height above target player's position
                m.pos.x = targetPlayer.pos.x
                m.pos.y = targetPlayer.pos.y + MARIO_HEIGHT
                m.pos.z = targetPlayer.pos.z

                -- Update last warped index for next cycle
                lastWarpedPlayerIndex = nextPlayerIndex
            end
        end
    else
        -- Not in bubble, reset speed multiplier
        bubbleSpeedMultiplier = MIN_SPEED_MULTIPLIER
    end
end

-- Hook into mario update to handle button presses
hook_event(HOOK_MARIO_UPDATE, mario_update)
