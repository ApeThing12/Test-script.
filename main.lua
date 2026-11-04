
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
local SettingsTab = Window:CreateTab("Settings", 4483362458)

CombatTab:CreateSection("Combat Features")

--==================================================
-- CONFIGURATION
--==================================================

local GREEN = Color3.fromRGB(0, 255, 110)
local DARK = Color3.fromRGB(12, 17, 20)

local Config = {
    PlayerHighlight = false,
    Nametags = false,
    Username = true,
    Distance = true,
    Health = true,
    HeadHighlight = false,
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

    if data.Tag and data.Tag.Billboard then
        data.Tag.Billboard:Destroy()
    end

    Visuals[player] = nil
end

--==================================================
-- NAMETAG CREATOR
--==================================================

local function createNametag(player, character, head)

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerNametag"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(145, 54)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 250
    billboard.Parent = character

    -- Main container
    local frame = Instance.new("Frame")
    frame.Name = "Container"
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = DARK
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = frame

    -- Neon border
    local stroke = Instance.new("UIStroke")
    stroke.Color = GREEN
    stroke.Thickness = 1.3
    stroke.Transparency = 0.1
    stroke.Parent = frame

    -- Gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(
            0,
            Color3.fromRGB(20, 32, 29)
        ),
        ColorSequenceKeypoint.new(
            1,
            Color3.fromRGB(8, 11, 15)
        )
    })
    gradient.Rotation = 90
    gradient.Parent = frame

    -- Accent line
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0.35, 0, 0, 2)
    accent.Position = UDim2.new(0.325, 0, 0, 0)
    accent.BackgroundColor3 = GREEN
    accent.BorderSizePixel = 0
    accent.Parent = frame

    -- Label helper
    local function makeLabel(name, position, height)
        local label = Instance.new("TextLabel")
        label.Name = name
        label.Position = position
        label.Size = UDim2.new(1, -10, 0, height)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 10
        label.Font = Enum.Font.GothamMedium
        label.Parent = frame

        return label
    end

    -- Username
    local username = makeLabel(
        "Username",
        UDim2.fromOffset(5, 3),
        19
    )

    username.Text = player.DisplayName
    username.TextColor3 = GREEN
    username.TextSize = 12
    username.Font = Enum.Font.GothamBold
    username.TextTruncate = Enum.TextTruncate.AtEnd
    username.Visible = Config.Username

    -- Distance
    local distance = makeLabel(
        "Distance",
        UDim2.fromOffset(5, 24),
        13
    )

    distance.TextColor3 = Color3.fromRGB(190, 200, 200)
    distance.Visible = Config.Distance

    -- Health
    local health = makeLabel(
        "Health",
        UDim2.fromOffset(5, 38),
        13
    )

    health.TextColor3 = GREEN
    health.Visible = Config.Health

    return {
        Billboard = billboard,
        Username = username,
        Distance = distance,
        Health = health
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
-- DISTANCE / HEALTH UPDATER
--==================================================

local elapsed = 0

track(RunService.Heartbeat:Connect(function(dt)

    if Unloaded then return end

    elapsed += dt

    if elapsed < 0.1 then
        return
    end

    elapsed = 0

    local myCharacter = LocalPlayer.Character

    local myRoot = myCharacter
        and myCharacter:FindFirstChild("HumanoidRootPart")

    for player, data in pairs(Visuals) do

        local character = player.Character

        if character and data.Tag then

            local root = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            data.Tag.Username.Visible = Config.Username
            data.Tag.Distance.Visible = Config.Distance
            data.Tag.Health.Visible = Config.Health

            if Config.Distance and root and myRoot then

                local distance = (
                    myRoot.Position - root.Position
                ).Magnitude

                data.Tag.Distance.Text = string.format(
                    "%d studs",
                    distance
                )
            end

            if Config.Health and humanoid then

                data.Tag.Health.Text = string.format(
                    "HP: %d / %d",
                    humanoid.Health,
                    humanoid.MaxHealth
                )
            end
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
    Name = "Fancy Nametags",
    CurrentValue = false,

    Callback = function(value)

        Config.Nametags = value
        refreshAll()

    end
})

ESPTab:CreateToggle({
    Name = "Display Username",
    CurrentValue = true,

    Callback = function(value)

        Config.Username = value

        for _, data in pairs(Visuals) do
            if data.Tag then
                data.Tag.Username.Visible = value
            end
        end

    end
})

ESPTab:CreateToggle({
    Name = "Display Distance",
    CurrentValue = true,

    Callback = function(value)

        Config.Distance = value

        for _, data in pairs(Visuals) do
            if data.Tag then
                data.Tag.Distance.Visible = value
            end
        end

    end
})

ESPTab:CreateToggle({
    Name = "Display Health",
    CurrentValue = true,

    Callback = function(value)

        Config.Health = value

        for _, data in pairs(Visuals) do
            if data.Tag then
                data.Tag.Health.Visible = value
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
