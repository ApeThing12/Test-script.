--==================================================
-- PLAYER TOOLS | RAYFIELD
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- RAYFIELD INITIALIZATION
--==================================================

local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/rayfield"
))()

local Window = Rayfield:CreateWindow({
    Name = "Player Tools",
    LoadingTitle = "Player Tools",
    LoadingSubtitle = "Visual Suite",
    Theme = "Default",

    ConfigurationSaving = {
        Enabled = false
    }
})

--==================================================
-- TABS
--==================================================

local ESPTab = Window:CreateTab("Player ESP", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)
local AntisTab = Window:CreateTab("Antis", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

CombatTab:CreateSection("Combat Features")

--==================================================
-- CONFIGURATION
--==================================================

local GREEN = Color3.fromRGB(0, 255, 110)
local DARK = Color3.fromRGB(12, 17, 20)

local Config = {
    PlayerHighlight = false,
    BoxESP = false,
    Nametags = false,
    Username = true,
    HeadHighlight = false,
    AntiFling = false,
    OutlineTransparency = 0
}

local Visuals = {}
local Connections = {}
local Unloaded = false

local function track(connection)
    table.insert(Connections, connection)
    return connection
end

--==================================================
-- CLEANUP SYSTEM
--==================================================

local function clearPlayer(player)
    local data = Visuals[player]

    if not data then return end

    if data.Body then
        data.Body:Destroy()
    end

    if data.Head then
        data.Head:Destroy()
    end

    if data.Box then
        data.Box:Destroy()
    end

    if data.Tag and data.Tag.Billboard then
        data.Tag.Billboard:Destroy()

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            humanoid.DisplayDistanceType =
                Enum.HumanoidDisplayDistanceType.Viewer
        end
    end

    Visuals[player] = nil
end

--==================================================
-- SIMPLE DISPLAY-NAME TAG
--==================================================

local function createNametag(player, character, head)

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.DisplayDistanceType =
            Enum.HumanoidDisplayDistanceType.None
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerNametag"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(160, 25)
    billboard.StudsOffset = Vector3.new(0, 2.7, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 250
    billboard.Parent = character

    local username = Instance.new("TextLabel")
    username.Name = "Username"
    username.BackgroundTransparency = 1
    username.Size = UDim2.fromScale(1, 1)
    username.Font = Enum.Font.GothamBold
    username.Text = player.DisplayName
    username.TextColor3 = GREEN
    username.TextSize = 14
    username.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    username.TextStrokeTransparency = 0.25
    username.TextTruncate = Enum.TextTruncate.AtEnd
    username.Parent = billboard

    return {
        Billboard = billboard,
        Username = username
    }
end

--==================================================
-- APPLY VISUALS
--==================================================

local function applyPlayer(player)

    if Unloaded or player == LocalPlayer then
        return
    end

    clearPlayer(player)

    local character = player.Character
    if not character then return end

    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not head or not humanoid then
        return
    end

    local data = {}
    Visuals[player] = data

    -- Fancy 3D bounding box
    if Config.BoxESP then

        local box = Instance.new("SelectionBox")
        box.Name = "PlayerBoxESP"
        box.Adornee = character
        box.Color3 = GREEN
        box.SurfaceColor3 = GREEN
        box.SurfaceTransparency = 1
        box.LineThickness = 0.045
        box.Transparency = 0
        box.AlwaysOnTop = true
        box.Parent = character

        data.Box = box
    end

    -- Full body highlight
    if Config.PlayerHighlight then

        local highlight = Instance.new("Highlight")
        highlight.Name = "PlayerHighlight"
        highlight.Adornee = character
        highlight.FillColor = GREEN
        highlight.OutlineColor = GREEN
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = Config.OutlineTransparency
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character

        data.Body = highlight
    end

    -- Head highlight
    if Config.HeadHighlight then

        local highlight = Instance.new("Highlight")
        highlight.Name = "HeadHighlight"
        highlight.Adornee = head
        highlight.FillColor = GREEN
        highlight.OutlineColor = GREEN
        highlight.FillTransparency = 0.2
        highlight.OutlineTransparency = Config.OutlineTransparency
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character

        data.Head = highlight
    end

    -- Nametag
    if Config.Nametags then
        data.Tag = createNametag(player, character, head)
    end
end

local function refreshAll()

    if Unloaded then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            applyPlayer(player)
        end
    end
end

--==================================================
-- PLAYER TRACKING
--==================================================

local function setupPlayer(player)

    if player == LocalPlayer then
        return
    end

    track(player.CharacterAdded:Connect(function(character)

        task.wait(0.5)

        if Unloaded then return end

        if player.Character == character then
            applyPlayer(player)
        end
    end))

    if player.Character then

        task.spawn(function()

            task.wait(0.5)

            if not Unloaded then
                applyPlayer(player)
            end

        end)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

track(Players.PlayerAdded:Connect(setupPlayer))

track(Players.PlayerRemoving:Connect(function(player)
    clearPlayer(player)
end))

--==================================================
-- ANTI-FLING
--==================================================

local FLING_SPEED_THRESHOLD = 120
local FLING_ANGULAR_THRESHOLD = 80

local function antiFling()

    if not Config.AntiFling then
        return
    end

    local character = LocalPlayer.Character
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local velocity = root.AssemblyLinearVelocity

    local horizontalSpeed = Vector3.new(
        velocity.X,
        0,
        velocity.Z
    ).Magnitude

    -- Counter extreme horizontal launches
    if horizontalSpeed > FLING_SPEED_THRESHOLD then

        root.AssemblyLinearVelocity = Vector3.new(
            0,
            math.clamp(velocity.Y, -80, 80),
            0
        )

    end

    -- Counter extreme spinning
    if root.AssemblyAngularVelocity.Magnitude > FLING_ANGULAR_THRESHOLD then

        root.AssemblyAngularVelocity = Vector3.zero

    end
end

--==================================================
-- DISPLAY-NAME REFRESH
--==================================================

local elapsed = 0

track(RunService.Heartbeat:Connect(function(dt)

    if Unloaded then return end

    antiFling()

    elapsed += dt

    if elapsed < 0.25 then
        return
    end

    elapsed = 0

    for player, data in pairs(Visuals) do

        if data.Tag and data.Tag.Username then

            data.Tag.Username.Text = player.DisplayName
            data.Tag.Username.Visible = Config.Username

        end

    end
end))

--==================================================
-- PLAYER ESP TAB
--==================================================

ESPTab:CreateSection("Player Highlights")

ESPTab:CreateToggle({
    Name = "Green Player Highlight",
    CurrentValue = false,

    Callback = function(value)

        Config.PlayerHighlight = value
        refreshAll()

    end
})

ESPTab:CreateToggle({
    Name = "Fancy Box ESP",
    CurrentValue = false,

    Callback = function(value)

        Config.BoxESP = value
        refreshAll()

    end
})

ESPTab:CreateToggle({
    Name = "Head Highlight",
    CurrentValue = false,

    Callback = function(value)

        Config.HeadHighlight = value
        refreshAll()

    end
})

--==================================================
-- NAMETAGS
--==================================================

ESPTab:CreateSection("Nametags")

ESPTab:CreateToggle({
    Name = "Display Name",
    CurrentValue = false,

    Callback = function(value)

        Config.Nametags = value
        refreshAll()

    end
})

ESPTab:CreateToggle({
    Name = "Show Display Name Text",
    CurrentValue = true,

    Callback = function(value)

        Config.Username = value

        for _, data in pairs(Visuals) do

            if data.Tag and data.Tag.Username then
                data.Tag.Username.Visible = value
            end

        end

    end
})

--==================================================
-- CUSTOMIZATION
--==================================================

ESPTab:CreateSection("Customization")

ESPTab:CreateSlider({
    Name = "Outline Transparency",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 0,

    Callback = function(value)

        Config.OutlineTransparency = value / 100

        for _, data in pairs(Visuals) do

            if data.Body then
                data.Body.OutlineTransparency =
                    Config.OutlineTransparency
            end

            if data.Head then
                data.Head.OutlineTransparency =
                    Config.OutlineTransparency
            end

        end
    end
})

--==================================================
-- ANTIS TAB
--==================================================

AntisTab:CreateSection("Movement Protection")

AntisTab:CreateToggle({
    Name = "Anti-Fling",
    CurrentValue = false,

    Callback = function(value)

        Config.AntiFling = value

    end
})

--==================================================
-- COMBAT TAB
--==================================================

CombatTab:CreateSection("Combat Features")

-- Reserved for future features.

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

        -- Destroy Rayfield interface
        Rayfield:Destroy()

        print("[Player Tools] Completely unloaded.")

    end
})

print("[Player Tools] Loaded successfully!")
