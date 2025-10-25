-- Complete Mobile Admin Script with ESP, Aimbot, Fog Controls
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
local espConnections = {} -- Store connections to clean up later
local espHighlights = {} -- Store highlight objects

local function createESP(player)
    if player == localPlayer then return end
    
    local function setupCharacterESP(character)
        -- Wait for character to fully load
        wait(1)
        
        -- Remove existing ESP if any
        if espHighlights[player] then
            espHighlights[player]:Destroy()
            espHighlights[player] = nil
        end
        
        local humanoid = character:WaitForChild("Humanoid")
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_" .. player.Name
        highlight.Adornee = character
        highlight.Parent = character
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        espHighlights[player] = highlight
    end
    
    -- Setup ESP for current character if exists
    if player.Character then
        setupCharacterESP(player.Character)
    end
    
    -- Connect to character added event (respawns and new characters)
    local characterConnection = player.CharacterAdded:Connect(function(character)
        if espEnabled then
            setupCharacterESP(character)
        end
    end)
    
    -- Store connection for cleanup
    espConnections[player] = characterConnection
end

local function removeESP(player)
    -- Remove highlight
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
    
    -- Disconnect character connection
    if espConnections[player] then
        espConnections[player]:Disconnect()
        espConnections[player] = nil
    end
end

local function toggleESP(enabled)
    espEnabled = enabled
    
    if enabled then
        -- Clear existing data
        for player, _ in pairs(espHighlights) do
            removeESP(player)
        end
        
        -- Create ESP for existing players
        for _, player in pairs(Players:GetPlayers()) do
            createESP(player)
        end
        
        -- Connect to new players joining
        local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
            createESP(player)
        end)
        
        -- Connect to players leaving
        local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
            removeESP(player)
        end)
        
        -- Store these connections
        espConnections["PlayerAdded"] = playerAddedConnection
        espConnections["PlayerRemoving"] = playerRemovingConnection
        
        print("ESP Enabled - Tracking all players")
        
    else
        -- Remove all ESP
        for _, player in pairs(Players:GetPlayers()) do
            removeESP(player)
        end
        
        -- Disconnect global connections
        if espConnections["PlayerAdded"] then
            espConnections["PlayerAdded"]:Disconnect()
            espConnections["PlayerAdded"] = nil
        end
        
        if espConnections["PlayerRemoving"] then
            espConnections["PlayerRemoving"]:Disconnect()
            espConnections["PlayerRemoving"] = nil
        end
        
        print("ESP Disabled - All tracking stopped")
    end
end

-- Aimbot Functionality
local aimbotConnection
local currentTarget = nil
local fovCircle = nil
local fovSize = 100 -- FOV circle size

-- Create visible FOV circle
local function createFOVCircle()
    if fovCircle then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AimbotFOV"
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Name = "FOVCircle"
    frame.Size = UDim2.new(0, fovSize, 0, fovSize)
    frame.Position = UDim2.new(0.5, -fovSize/2, 0.5, -fovSize/2)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    
    -- Create circle using UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0) -- Makes it a perfect circle
    corner.Parent = frame
    
    -- White outline
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1) -- White
    stroke.Thickness = 2
    stroke.Parent = frame
    
    frame.Parent = screenGui
    fovCircle = frame
end

local function removeFOVCircle()
    if fovCircle then
        fovCircle.Parent:Destroy()
        fovCircle = nil
    end
end

local function isInFOVCircle(targetHead)
    local localCamera = workspace.CurrentCamera
    if not localCamera then return false end
    
    -- Convert world position to screen position
    local targetPos = targetHead.Position
    local screenPoint, visible = localCamera:WorldToScreenPoint(targetPos)
    
    if not visible then return false end
    
    -- Get screen center
    local viewportSize = localCamera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    
    -- Calculate distance from center
    local screenPos = Vector2.new(screenPoint.X, screenPoint.Y)
    local distanceFromCenter = (screenPos - screenCenter).Magnitude
    
    -- Only target if within FOV circle radius
    local circleRadius = fovSize / 2
    return distanceFromCenter <= circleRadius
end

local function findClosestPlayerInFOV()
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
            
            -- Check if player is valid target
            if humanoid and humanoid.Health > 0 and head then
                -- Check if player is within FOV circle
                if isInFOVCircle(head) then
                    local distance = (localHead.Position - head.Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local function isValidTarget(player)
    if not player or not player.Character then return false end
    
    local character = player.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")
    
    return humanoid and humanoid.Health > 0 and head and isInFOVCircle(head)
end

local function updateAimbotTarget()
    if not aimbotEnabled then return end
    
    -- Check if current target is still valid
    if currentTarget and not isValidTarget(currentTarget) then
        currentTarget = nil
    end
    
    -- Find new target if needed
    if not currentTarget or not isValidTarget(currentTarget) then
        currentTarget = findClosestPlayerInFOV()
    end
    
    -- Aim at current target
    if currentTarget and isValidTarget(currentTarget) then
        local targetHead = currentTarget.Character:FindFirstChild("Head")
        local localCharacter = localPlayer.Character
        local localCamera = workspace.CurrentCamera
        
        if targetHead and localCharacter and localCamera then
            -- Smooth aimbot - point camera at target
            localCamera.CFrame = CFrame.lookAt(localCamera.CFrame.Position, targetHead.Position)
        end
    end
end

local function toggleAimbot(enabled)
    aimbotEnabled = enabled
    
    if enabled then
        -- Create FOV circle
        createFOVCircle()
        
        -- Reset target
        currentTarget = nil
        
        -- Start aimbot loop
        aimbotConnection = RunService.RenderStepped:Connect(function()
            updateAimbotTarget()
        end)
        
        print("Aimbot Enabled - White FOV circle visible (size: " .. fovSize .. ")")
        
    else
        -- Stop aimbot and remove FOV circle
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
        
        removeFOVCircle()
        currentTarget = nil
        print("Aimbot Disabled - FOV circle removed")
    end
end

-- Auto-update aimbot when players leave
Players.PlayerRemoving:Connect(function(player)
    if aimbotEnabled and currentTarget == player then
        currentTarget = nil
    end
end)

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

print("Complete Mobile Admin Script Loaded!")
print("Tap the crown button 👑 to open admin panel")
print("Features: ESP, Aimbot with FOV circle, Fog controls, Draggable panel")
