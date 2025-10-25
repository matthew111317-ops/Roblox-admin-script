-- Complete Mobile Admin Script with Team Check, Wall Check, and Improved FOV
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

-- Team Check Function
local function isEnemy(player)
    if player == localPlayer then return false end
    
    -- Check if players are on different teams
    local localTeam = localPlayer.Team
    local playerTeam = player.Team
    
    if localTeam and playerTeam then
        return localTeam ~= playerTeam
    end
    
    -- If no teams, consider everyone enemy
    return true
end

-- Wall Check Function
local function isVisible(targetHead)
    local localCamera = workspace.CurrentCamera
    if not localCamera then return false end
    
    local cameraPos = localCamera.CFrame.Position
    local targetPos = targetHead.Position
    
    -- Raycast to check for walls
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {localPlayer.Character, targetHead.Parent}
    
    local raycastResult = workspace:Raycast(cameraPos, (targetPos - cameraPos), raycastParams)
    
    -- If raycast hits nothing, target is visible
    return raycastResult == nil
end

-- ESP Functionality
local espConnections = {}
local espHighlights = {}

local function createESP(player)
    if player == localPlayer then return end
    
    local function setupCharacterESP(character)
        wait(1)
        
        if espHighlights[player] then
            espHighlights[player]:Destroy()
            espHighlights[player] = nil
        end
        
        local humanoid = character:WaitForChild("Humanoid")
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_" .. player.Name
        highlight.Adornee = character
        highlight.Parent = character
        
        -- Color based on team
        if isEnemy(player) then
            highlight.FillColor = Color3.fromRGB(255, 0, 0)    -- Red for enemies
            highlight.OutlineColor = Color3.fromRGB(255, 100, 100)
        else
            highlight.FillColor = Color3.fromRGB(0, 255, 0)    -- Green for teammates
            highlight.OutlineColor = Color3.fromRGB(100, 255, 100)
        end
        
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        espHighlights[player] = highlight
    end
    
    if player.Character then
        setupCharacterESP(player.Character)
    end
    
    local characterConnection = player.CharacterAdded:Connect(function(character)
        if espEnabled then
            setupCharacterESP(character)
        end
    end)
    
    espConnections[player] = characterConnection
end

local function removeESP(player)
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
    
    if espConnections[player] then
        espConnections[player]:Disconnect()
        espConnections[player] = nil
    end
end

local function toggleESP(enabled)
    espEnabled = enabled
    
    if enabled then
        for player, _ in pairs(espHighlights) do
            removeESP(player)
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            createESP(player)
        end
        
        local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
            createESP(player)
        end)
        
        local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
            removeESP(player)
        end)
        
        espConnections["PlayerAdded"] = playerAddedConnection
        espConnections["PlayerRemoving"] = playerRemovingConnection
        
        print("ESP Enabled - Team colors: Red=Enemy, Green=Teammate")
        
    else
        for _, player in pairs(Players:GetPlayers()) do
            removeESP(player)
        end
        
        if espConnections["PlayerAdded"] then
            espConnections["PlayerAdded"]:Disconnect()
            espConnections["PlayerAdded"] = nil
        end
        
        if espConnections["PlayerRemoving"] then
            espConnections["PlayerRemoving"]:Disconnect()
            espConnections["PlayerRemoving"] = nil
        end
        
        print("ESP Disabled")
    end
end

-- Aimbot Functionality
local aimbotConnection
local currentTarget = nil
local fovCircle = nil
local fovSize = 150 -- Increased FOV size for better targeting

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
    corner.CornerRadius = UDim.new(1, 0)
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
    
    local targetPos = targetHead.Position
    local screenPoint, visible = localCamera:WorldToScreenPoint(targetPos)
    
    if not visible then return false end
    
    local viewportSize = localCamera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    
    local screenPos = Vector2.new(screenPoint.X, screenPoint.Y)
    local distanceFromCenter = (screenPos - screenCenter).Magnitude
    
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
        -- Team check: only target enemies
        if player ~= localPlayer and isEnemy(player) and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local head = character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and head then
                -- Wall check: only target visible players
                if isVisible(head) then
                    -- FOV check: only target players in FOV circle
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
    end
    
    return closestPlayer
end

local function isValidTarget(player)
    if not player or not player.Character then return false end
    
    local character = player.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")
    
    if not (humanoid and humanoid.Health > 0 and head) then
        return false
    end
    
    -- Check all conditions: enemy, visible, in FOV
    return isEnemy(player) and isVisible(head) and isInFOVCircle(head)
end

local function updateAimbotTarget()
    if not aimbotEnabled then return end
    
    if currentTarget and not isValidTarget(currentTarget) then
        currentTarget = nil
    end
    
    if not currentTarget or not isValidTarget(currentTarget) then
        currentTarget = findClosestPlayerInFOV()
    end
    
    if currentTarget and isValidTarget(currentTarget) then
        local targetHead = currentTarget.Character:FindFirstChild("Head")
        local localCharacter = localPlayer.Character
        local localCamera = workspace.CurrentCamera
        
        if targetHead and localCharacter and localCamera then
            localCamera.CFrame = CFrame.lookAt(localCamera.CFrame.Position, targetHead.Position)
        end
    end
end

local function toggleAimbot(enabled)
    aimbotEnabled = enabled
    
    if enabled then
        createFOVCircle()
        currentTarget = nil
        aimbotConnection = RunService.RenderStepped:Connect(function()
            updateAimbotTarget()
        end)
        
        print("Aimbot Enabled - Targeting enemies only (Wall Check: ON)")
        
    else
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
        removeFOVCircle()
        currentTarget = nil
        print("Aimbot Disabled")
    end
end

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
    wait(1)
    buttons.fog.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
end)
yPosition = yPosition + 70

-- Clear Fog Button
buttons.clearFog = createControlButton("Clear Fog", UDim2.new(0, 20, 0, yPosition), function()
    Lighting.FogEnd = 1000000
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

print("Enhanced Admin Script Loaded!")
print("Features: Team Check, Wall Check, Larger FOV (150)")
print("ESP: Red=Enemies, Green=Teammates")
print("Aimbot: Only targets visible enemies in FOV")
