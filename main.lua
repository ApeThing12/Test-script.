    end
})

--==================================================
-- COMBAT TAB
--==================================================

CombatTab:CreateSection("Aim Assist")

CombatTab:CreateToggle({
    Name = "Aim Assist",
    CurrentValue = false,

    Callback = function(value)
        Config.AimAssist = value
        updateAimCircle()
    end
})

CombatTab:CreateSlider({
    Name = "Aim FOV",
    Range = {40, 400},
    Increment = 10,
    Suffix = " px",
    CurrentValue = 120,

    Callback = function(value)
        Config.AimFOV = value
        updateAimCircle()
    end
})

CombatTab:CreateSlider({
    Name = "Aim Smoothness",
    Range = {1, 30},
    Increment = 1,
    Suffix = "",
    CurrentValue = 8,

    Callback = function(value)
        Config.AimSmoothness = value
    end
})

CombatTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,

    Callback = function(value)
        Config.ShowAimFOV = value
        updateAimCircle()
    end
})

CombatTab:CreateSection("Aim Controls")
-- Hold RIGHT MOUSE BUTTON to activate aim assist.

--==================================================
-- COMPLETE UNLOAD
--==================================================

SettingsTab:CreateSection("Script Management")

SettingsTab:CreateButton({
    Name = "Unload Everything",

    Callback = function()

        if Unloaded then
            return
        end

        Unloaded = true

        -- Disconnect all tracked connections
        for _, connection in ipairs(Connections) do

            if connection.Connected then
                connection:Disconnect()
            end

        end

        table.clear(Connections)

        -- Destroy every tracked visual
        for player in pairs(Visuals) do
            clearPlayer(player)
        end

        table.clear(Visuals)

        -- Remove any remaining script-created visuals
        for _, player in ipairs(Players:GetPlayers()) do

            local character = player.Character

            if character then

                for _, object in ipairs(character:GetDescendants()) do

                    if object.Name == "PlayerHighlight"
                    or object.Name == "HeadHighlight"
                    or object.Name == "PlayerBoxESP"
                    or object.Name == "PlayerNametag" then

                        object:Destroy()

                    end

                end
            end
        end

        -- Destroy aim FOV overlay
        if aimCircleGui then
            aimCircleGui:Destroy()
            aimCircleGui = nil
            aimCircle = nil
            aimStroke = nil
        end

        aimHeld = false

        -- Destroy Rayfield interface
        Rayfield:Destroy()

        print("[Player Tools] Completely unloaded.")
