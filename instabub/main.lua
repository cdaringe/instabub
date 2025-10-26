-- instabub mod for SM64CoopDX
-- Press D-pad Up to instantly enter bubble
-- While in bubble: D-pad Down to warp to next player
-- Press D-pad Up rapidly 3 times to exit bubble (de-bubble)

-- Track which player we last warped to
local lastWarpedPlayerIndex = 0

-- Mario's height for offset
local MARIO_HEIGHT = 160

-- Track the last 3 up d-pad press timestamps for triple-press detection
local upPressTimestamps = {0, 0, 0}
local TRIPLE_PRESS_WINDOW = 0.5  -- Time window in seconds for triple press

-- Check if we have 3 rapid presses within the time window
local function check_triple_press()
    local currentTime = upPressTimestamps[3]
    local firstTime = upPressTimestamps[1]
    return (currentTime - firstTime) <= TRIPLE_PRESS_WINDOW
end

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

    -- Check if D-pad Up was just pressed
    if (m.controller.buttonPressed & U_JPAD) ~= 0 then
        -- Get current time (frame-based timing)
        local currentTime = get_global_timer() / 30.0  -- Convert frames to seconds (30 FPS)

        -- Shift timestamps and add new press
        upPressTimestamps[1] = upPressTimestamps[2]
        upPressTimestamps[2] = upPressTimestamps[3]
        upPressTimestamps[3] = currentTime

        -- Check for triple press
        if check_triple_press() and m.action == ACT_BUBBLED then
            -- De-bubble: exit bubble state
            set_mario_action(m, ACT_IDLE, 0)
        elseif m.action ~= ACT_BUBBLED then
            -- Enter bubble (only if not already bubbled)
            set_mario_action(m, ACT_BUBBLED, 0)
        end
    end

    -- Only process bubble controls if already in bubble
    if m.action == ACT_BUBBLED then
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
    end
end

-- Hook into mario update to handle button presses
hook_event(HOOK_MARIO_UPDATE, mario_update)
