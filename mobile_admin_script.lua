-- Mobile Admin Script with ESP, Aimbot, and Fog Control
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local adminEnabled = false
local espEnabled = false
local aimbotEnabled = false

-- Create Mobile-Friendly GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileAdminPanel"
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Main Admin Button (floating button to open panel)
local adminToggleButton = Instance.new("TextButton")
adminToggleButton.Name = "AdminToggle"
adminToggleButton.Size = UDim2.new(0, 80, 0, 80)
adminToggleButton.Position = UDim2.new(1, -90, 0, 20)
adminToggleButton.AnchorPoint = Vector2.new(0, 0)
adminToggleButton.Text = "👑"
adminToggleButton.TextScaled = true
adminToggleButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
adminToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
adminToggleButton.BorderSizePixel = 0
adminToggleButton.ZIndex = 10

-- Add rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.3, 0)
corner.Parent = adminToggleButton

adminToggleButton.Parent = screenGui

-- Control Panel (hidden by default)
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Size = UDim2.new(0, 300, 0, 400)
controlPanel.Position = UDim2.new(0.5, -150, 0.5, -200)
controlPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
controlPanel.Visible = false
controlPanel.ZIndex = 5

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0.05, 0)
panelCorner.Parent = controlPanel

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 280, 0, 50)
title.Position = UDim2.new(0, 10, 0, 10)
title.Text = "ADMIN PANEL"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = controlPanel

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0, 10)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeButton.TextScaled = true
closeButton.ZIndex = 6

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0.3, 0)
closeCorner.Parent = closeButton
closeButton.Parent = controlPanel

controlPanel.Parent = screenGui

-- ESP Functionality
local function createESP(player)
    if player == localPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    -- Remove existing ESP if any
    removeESP(player)
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_" .. player.Name
    highlight.Adornee = character
    highlight.Parent = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function removeESP(player)
    if player.Character then
        local esp = player.Character:FindFirstChild("ESP_" .. player.Name)
        if esp then
            esp:Destroy()
        end
    end
end

local function toggleESP(enabled)
    espEnabled = enabled
    
    if enabled then
        -- Create ESP for existing players
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                createESP(player)
            end
        end
        
        -- Connect to new players
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(character)
                wait(1)
                createESP(player)
            end)
        end)
        
        -- Handle character respawns
        for _, player in pairs(Players:GetPlayers()) do
            player.CharacterAdded:Connect(function(character)
                wait(1)
                createESP(player)
            end)
        end
    else
        -- Remove all ESP
        for _, player in pairs(Players:GetPlayers()) do
            removeESP(player)
        end
    end
end

-- Aimbot Functionality
local function findClosestPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge
    local localCharacter = localPlayer.Character
    local localHead = localCharacter and localCharacter:FindFirstChild("Head")
    
    if not localHead then return nil end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local head = character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and head then
                local distance = (localHead.Position - head.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

local aimbotConnection
local function toggleAimbot(enabled)
    aimbotEnabled = enabled
    
    if enabled then
        aimbotConnection = RunService.RenderStepped:Connect(function()
            if not aimbotEnabled then return end
            
            local closestPlayer = findClosestPlayer()
            if closestPlayer and closestPlayer.Character then
                local targetHead = closestPlayer.Character:FindFirstChild("Head")
                local localCharacter = localPlayer.Character
                local localCamera = workspace.CurrentCamera
                
                if targetHead and localCharacter and localCamera then
                    -- Simple aimbot - point camera at target
                    localCamera.CFrame = CFrame.lookAt(localCamera.CFrame.Position, targetHead.Position)
                end
            end
        end)
    else
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end
end

-- Fog Control
local function setFog(density)
    Lighting.FogStart = 0
    Lighting.FogEnd = density or 100
    Lighting.GlobalShadows = false
    print("Fog set to distance: " .. tostring(density))
end

-- Create Control Buttons
local function createControlButton(name, position, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 260, 0, 60)
    button.Position = position
    button.Text = name
    button.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.AutoButtonColor = true
    button.ZIndex = 6
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0.1, 0)
    buttonCorner.Parent = button
    
    button.MouseButton1Click:Connect(callback)
    button.Parent = controlPanel
    
    return button
end

-- Create all control buttons
local buttons = {}
local yPosition = 70

-- ESP Toggle Button
buttons.esp = createControlButton("ESP: OFF", UDim2.new(0, 20, 0, yPosition), function()
    espEnabled = not espEnabled
    buttons.esp.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
    buttons.esp.BackgroundColor3 = espEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(52, 152, 219)
    toggleESP(espEnabled)
end)
yPosition = yPosition + 70

-- Aimbot Toggle Button
buttons.aimbot = createControlButton("Aimbot: OFF", UDim2.new(0, 20, 0, yPosition), function()
    aimbotEnabled = not aimbotEnabled
    buttons.aimbot.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    buttons.aimbot.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(52, 152, 219)
    toggleAimbot(aimbotEnabled)
end)
yPosition = yPosition + 70

-- Fog Button
buttons.fog = createControlButton("Set Fog (100)", UDim2.new(0, 20, 0, yPosition), function()
    setFog(100)
    buttons.fog.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
    -- Reset color after 1 second
    wait(1)
    buttons.fog.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
end)
yPosition = yPosition + 70

-- Clear Fog Button
buttons.clearFog = createControlButton("Clear Fog", UDim2.new(0, 20, 0, yPosition), function()
    Lighting.FogEnd = 1000000 -- Effectively disables fog
    buttons.clearFog.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
    wait(1)
    buttons.clearFog.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    print("Fog cleared")
end)
yPosition = yPosition + 70

-- Close Panel Button
buttons.close = createControlButton("Close Panel", UDim2.new(0, 20, 0, yPosition), function()
    controlPanel.Visible = false
    adminToggleButton.Visible = true
end)

-- Panel Toggle Functions
adminToggleButton.MouseButton1Click:Connect(function()
    controlPanel.Visible = true
    adminToggleButton.Visible = false
end)

closeButton.MouseButton1Click:Connect(function()
    controlPanel.Visible = false
    adminToggleButton.Visible = true
end)

-- Make panel draggable
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    controlPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

controlPanel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = controlPanel.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

controlPanel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

print("Mobile Admin Script Loaded!")
print("Tap the crown button 👑 to open admin panel")
