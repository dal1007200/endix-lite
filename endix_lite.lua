-- Endix Lite - by bio0n
-- Press INSERT | Kill Aura + Movement + Anti Collision + Knockback + Teleport

local UIS = game:GetService("UserInputService")
local CG = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RS = game:GetService("RunService")
local VI = game:GetService("VirtualInputManager")

local C = {
    bg=Color3.fromRGB(15,8,10), bg2=Color3.fromRGB(28,18,22), bg3=Color3.fromRGB(40,25,30),
    accent=Color3.fromRGB(220,40,60), text=Color3.fromRGB(255,255,255), textDim=Color3.fromRGB(200,170,170),
    success=Color3.fromRGB(80,220,100), red=Color3.fromRGB(255,50,70), green=Color3.fromRGB(0,255,100),
    blue=Color3.fromRGB(50,100,255), yellow=Color3.fromRGB(255,200,0), pink=Color3.fromRGB(255,100,200), white=Color3.fromRGB(255,255,255)
}

local gui = Instance.new("ScreenGui")
gui.Name = "EndixLite"
gui.Parent = CG

-- Watermark
local wm = Instance.new("Frame")
wm.Size = UDim2.new(0,140,0,45)
wm.Position = UDim2.new(1,-150,0,10)
wm.BackgroundColor3 = C.bg
wm.BackgroundTransparency = 0.2
wm.BorderSizePixel = 1
wm.BorderColor3 = C.accent
wm.Parent = gui
local wmC = Instance.new("UICorner")
wmC.CornerRadius = UDim.new(0,12)
wmC.Parent = wm
local wmTitle = Instance.new("TextLabel")
wmTitle.Size = UDim2.new(1,0,0,28)
wmTitle.Text = "ENDIX LITE"
wmTitle.TextColor3 = C.text
wmTitle.BackgroundTransparency = 1
wmTitle.Font = Enum.Font.GothamBold
wmTitle.TextSize = 12
wmTitle.Parent = wm
local wmVer = Instance.new("TextLabel")
wmVer.Size = UDim2.new(1,0,0,15)
wmVer.Position = UDim2.new(0,0,0.55,0)
wmVer.Text = "by bio0n | INSERT"
wmVer.TextColor3 = C.textDim
wmVer.BackgroundTransparency = 1
wmVer.Font = Enum.Font.Gotham
wmVer.TextSize = 9
wmVer.Parent = wm

-- Kill Aura Variables
local killAura = false
local killMode = "Smooth"
local killRange = 15
local killDelay = 0.05
local killLoop = nil

-- Movement Variables
local speedHack = false
local speedVal = 48
local infiniteJump = false
local jumpConn = nil

-- Extra Variables
local savedPos = nil
local noCollision = false
local knockback = false
local originalCollision = {}
local knockbackPower = 50
local knockbackLoop = nil

-- Teleport Coordinates
local teleportPoints = {
    {name="Arena", x=0, y=5, z=0},
    {name="Train", x=150, y=5, z=50},
    {name="Alley", x=-80, y=5, z=80},
    {name="Roof", x=0, y=50, z=0},
}

-- Keybinds
local keybinds = {
    KillAura = {key = Enum.KeyCode.K, enabled = true},
    SpeedHack = {key = Enum.KeyCode.V, enabled = true},
    InfiniteJump = {key = Enum.KeyCode.J, enabled = true},
    NoCollision = {key = Enum.KeyCode.N, enabled = true},
    Knockback = {key = Enum.KeyCode.U, enabled = true},
}

-- Teleport Function
local function tpToPos(pos)
    local char = LP.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(pos) end
    end
end

local function tpToCoords(x, y, z)
    tpToPos(Vector3.new(x, y, z))
end

-- Speed
local function setSpeed()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = speedHack and speedVal or 16 end
end

-- Infinite Jump
local function setInfiniteJump()
    if infiniteJump then
        if jumpConn then jumpConn:Disconnect() end
        jumpConn = UIS.JumpRequest:Connect(function()
            local char = LP.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if jumpConn then jumpConn:Disconnect() end
    end
end

-- No Collision
local function setNoCollision()
    local char = LP.Character
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if noCollision then
                originalCollision[part] = part.CanCollide
                part.CanCollide = false
            else
                part.CanCollide = originalCollision[part] ~= nil and originalCollision[part] or true
            end
        end
    end
    
    if noCollision then
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= LP and other.Character then
                for _, part in ipairs(other.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    else
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= LP and other.Character then
                for _, part in ipairs(other.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
end

local function monitorNewParts()
    local char = LP.Character
    if not char then return end
    char.DescendantAdded:Connect(function(part)
        if noCollision and part:IsA("BasePart") then
            originalCollision[part] = part.CanCollide
            part.CanCollide = false
        end
    end)
end

-- Knockback
local function startKnockback()
    if knockbackLoop then knockbackLoop:Disconnect() end
    knockbackLoop = RS.Heartbeat:Connect(function()
        if not knockback then return end
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local tr = plr.Character:FindFirstChild("HumanoidRootPart")
                if tr then
                    local dist = (root.Position - tr.Position).Magnitude
                    if dist < 10 then
                        local dir = (tr.Position - root.Position).Unit
                        local vel = Instance.new("BodyVelocity")
                        vel.MaxForce = Vector3.new(1,1,1) * 10000
                        vel.Velocity = dir * knockbackPower
                        vel.Parent = tr
                        game:GetService("Debris"):AddItem(vel, 0.3)
                    end
                end
            end
        end
    end)
end

-- Kill Aura
local function getClosestTarget()
    local char = LP.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local closest, dist = nil, killRange
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local tr = plr.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local d = (root.Position - tr.Position).Magnitude
                if d < dist then dist = d; closest = plr end
            end
        end
    end
    return closest
end

-- Aimbot: 100% hitting
local function aimbotAttack(target)
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
    
    VI:SendMouseButtonEvent(0,0,0,true,game,0)
    task.wait(0.02)
    VI:SendMouseButtonEvent(0,0,0,false,game,0)
end

local function startKillAura()
    if killLoop then killLoop:Disconnect() end
    killLoop = RS.Heartbeat:Connect(function()
        if not killAura then return end
        local target = getClosestTarget()
        if not target then return end
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local tr = target.Character:FindFirstChild("HumanoidRootPart")
        if not tr then return end
        
        root.CFrame = CFrame.new(root.Position, tr.Position)
        
        if killMode == "Smooth" then
            VI:SendMouseButtonEvent(0,0,0,true,game,0)
            task.wait(killDelay)
            VI:SendMouseButtonEvent(0,0,0,false,game,0)
        elseif killMode == "Rage" then
            for i = 1, 3 do
                VI:SendMouseButtonEvent(0,0,0,true,game,0)
                task.wait(0.02)
                VI:SendMouseButtonEvent(0,0,0,false,game,0)
                task.wait(0.02)
            end
        elseif killMode == "Aimbot" then
            aimbotAttack(target)
        end
    end)
end

-- Keybind Handler
UIS.InputBegan:Connect(function(inp)
    if keybinds.KillAura.enabled and inp.KeyCode == keybinds.KillAura.key then 
        killAura = not killAura
        if killAura then startKillAura() else if killLoop then killLoop:Disconnect(); killLoop=nil end end
    end
    if keybinds.SpeedHack.enabled and inp.KeyCode == keybinds.SpeedHack.key then speedHack = not speedHack; setSpeed() end
    if keybinds.InfiniteJump.enabled and inp.KeyCode == keybinds.InfiniteJump.key then infiniteJump = not infiniteJump; setInfiniteJump() end
    if keybinds.NoCollision.enabled and inp.KeyCode == keybinds.NoCollision.key then noCollision = not noCollision; setNoCollision() end
    if keybinds.Knockback.enabled and inp.KeyCode == keybinds.Knockback.key then knockback = not knockback; if knockback then startKnockback() else if knockbackLoop then knockbackLoop:Disconnect(); knockbackLoop=nil end end end
end)

-- Character Added
local function onCharAdded(char)
    task.wait(1)
    setSpeed()
    setInfiniteJump()
    setNoCollision()
    if killAura then startKillAura() end
    if knockback then startKnockback() end
    monitorNewParts()
end

LP.CharacterAdded:Connect(onCharAdded)
if LP.Character then task.wait(1); onCharAdded(LP.Character) end

-- Settings Popup Functions
local function showKillAuraSettings()
    local pop = Instance.new("Frame")
    pop.Size = UDim2.new(0, 320, 0, 240)
    pop.Position = UDim2.new(0.5, -160, 0.5, -120)
    pop.BackgroundColor3 = C.bg2
    pop.BackgroundTransparency = 0.1
    pop.BorderSizePixel = 1
    pop.BorderColor3 = C.accent
    pop.Parent = gui
    local popCorner = Instance.new("UICorner")
    popCorner.CornerRadius = UDim.new(0, 12)
    popCorner.Parent = pop
    local popTitle = Instance.new("TextLabel")
    popTitle.Size = UDim2.new(1, 0, 0, 40)
    popTitle.Text = "Kill Aura"
    popTitle.TextColor3 = C.accent
    popTitle.BackgroundColor3 = C.bg
    popTitle.Font = Enum.Font.GothamBold
    popTitle.TextSize = 16
    popTitle.Parent = pop
    
    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(0.8, 0, 0, 35)
    modeBtn.Position = UDim2.new(0.1, 0, 0, 45)
    modeBtn.Text = "Mode: "..killMode
    modeBtn.TextColor3 = C.text
    modeBtn.BackgroundColor3 = C.bg
    modeBtn.Font = Enum.Font.Gotham
    modeBtn.TextSize = 13
    modeBtn.Parent = pop
    modeBtn.MouseButton1Click:Connect(function()
        if killMode == "Smooth" then
            killMode = "Rage"
        elseif killMode == "Rage" then
            killMode = "Aimbot"
        else
            killMode = "Smooth"
        end
        modeBtn.Text = "Mode: "..killMode
    end)
    
    local rangeFrame = Instance.new("Frame")
    rangeFrame.Size = UDim2.new(0.8, 0, 0, 35)
    rangeFrame.Position = UDim2.new(0.1, 0, 0, 90)
    rangeFrame.BackgroundColor3 = C.bg
    rangeFrame.Parent = pop
    local rangeLabel = Instance.new("TextLabel")
    rangeLabel.Size = UDim2.new(0.5, 0, 1, 0)
    rangeLabel.Text = "Range: "..killRange
    rangeLabel.TextColor3 = C.text
    rangeLabel.BackgroundTransparency = 1
    rangeLabel.Font = Enum.Font.Gotham
    rangeLabel.TextSize = 12
    rangeLabel.Parent = rangeFrame
    local rangeMinus = Instance.new("TextButton")
    rangeMinus.Size = UDim2.new(0.15, 0, 0.7, 0)
    rangeMinus.Position = UDim2.new(0.7, 0, 0.15, 0)
    rangeMinus.Text = "-"
    rangeMinus.BackgroundColor3 = C.bg3
    rangeMinus.Font = Enum.Font.GothamBold
    rangeMinus.TextSize = 14
    rangeMinus.Parent = rangeFrame
    local rangePlus = Instance.new("TextButton")
    rangePlus.Size = UDim2.new(0.15, 0, 0.7, 0)
    rangePlus.Position = UDim2.new(0.85, 0, 0.15, 0)
    rangePlus.Text = "+"
    rangePlus.BackgroundColor3 = C.bg3
    rangePlus.Font = Enum.Font.GothamBold
    rangePlus.TextSize = 14
    rangePlus.Parent = rangeFrame
    rangeMinus.MouseButton1Click:Connect(function() killRange = math.max(10, killRange - 1); rangeLabel.Text = "Range: "..killRange end)
    rangePlus.MouseButton1Click:Connect(function() killRange = math.min(30, killRange + 1); rangeLabel.Text = "Range: "..killRange end)
    
    local delayFrame = Instance.new("Frame")
    delayFrame.Size = UDim2.new(0.8, 0, 0, 35)
    delayFrame.Position = UDim2.new(0.1, 0, 0, 135)
    delayFrame.BackgroundColor3 = C.bg
    delayFrame.Parent = pop
    local delayLabel = Instance.new("TextLabel")
    delayLabel.Size = UDim2.new(0.5, 0, 1, 0)
    delayLabel.Text = "Delay: "..(killDelay*100).."ms"
    delayLabel.TextColor3 = C.text
    delayLabel.BackgroundTransparency = 1
    delayLabel.Font = Enum.Font.Gotham
    delayLabel.TextSize = 12
    delayLabel.Parent = delayFrame
    local delayMinus = Instance.new("TextButton")
    delayMinus.Size = UDim2.new(0.15, 0, 0.7, 0)
    delayMinus.Position = UDim2.new(0.7, 0, 0.15, 0)
    delayMinus.Text = "-"
    delayMinus.BackgroundColor3 = C.bg3
    delayMinus.Font = Enum.Font.GothamBold
    delayMinus.TextSize = 14
    delayMinus.Parent = delayFrame
    local delayPlus = Instance.new("TextButton")
    delayPlus.Size = UDim2.new(0.15, 0, 0.7, 0)
    delayPlus.Position = UDim2.new(0.85, 0, 0.15, 0)
    delayPlus.Text = "+"
    delayPlus.BackgroundColor3 = C.bg3
    delayPlus.Font = Enum.Font.GothamBold
    delayPlus.TextSize = 14
    delayPlus.Parent = delayFrame
    delayMinus.MouseButton1Click:Connect(function() killDelay = math.max(0.02, killDelay - 0.01); delayLabel.Text = "Delay: "..(killDelay*100).."ms" end)
    delayPlus.MouseButton1Click:Connect(function() killDelay = math.min(0.2, killDelay + 0.01); delayLabel.Text = "Delay: "..(killDelay*100).."ms" end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0.35, 0, 0, 35)
    close.Position = UDim2.new(0.325, 0, 0, 180)
    close.Text = "CLOSE"
    close.TextColor3 = C.textDim
    close.BackgroundColor3 = C.bg3
    close.Font = Enum.Font.GothamBold
    close.TextSize = 13
    close.Parent = pop
    close.MouseButton1Click:Connect(function() pop:Destroy() end)
end

local function showSpeedSettings()
    local pop = Instance.new("Frame")
    pop.Size = UDim2.new(0, 320, 0, 120)
    pop.Position = UDim2.new(0.5, -160, 0.5, -60)
    pop.BackgroundColor3 = C.bg2
    pop.BackgroundTransparency = 0.1
    pop.BorderSizePixel = 1
    pop.BorderColor3 = C.accent
    pop.Parent = gui
    local popCorner = Instance.new("UICorner")
    popCorner.CornerRadius = UDim.new(0, 12)
    popCorner.Parent = pop
    local popTitle = Instance.new("TextLabel")
    popTitle.Size = UDim2.new(1, 0, 0, 40)
    popTitle.Text = "Speed Hack"
    popTitle.TextColor3 = C.accent
    popTitle.BackgroundColor3 = C.bg
    popTitle.Font = Enum.Font.GothamBold
    popTitle.TextSize = 16
    popTitle.Parent = pop
    
    local speedFrame = Instance.new("Frame")
    speedFrame.Size = UDim2.new(0.8, 0, 0, 35)
    speedFrame.Position = UDim2.new(0.1, 0, 0, 45)
    speedFrame.BackgroundColor3 = C.bg
    speedFrame.Parent = pop
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0.5, 0, 1, 0)
    speedLabel.Text = "Speed: "..speedVal
    speedLabel.TextColor3 = C.text
    speedLabel.BackgroundTransparency = 1
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextSize = 12
    speedLabel.Parent = speedFrame
    local speedMinus = Instance.new("TextButton")
    speedMinus.Size = UDim2.new(0.15, 0, 0.7, 0)
    speedMinus.Position = UDim2.new(0.7, 0, 0.15, 0)
    speedMinus.Text = "-"
    speedMinus.BackgroundColor3 = C.bg3
    speedMinus.Font = Enum.Font.GothamBold
    speedMinus.TextSize = 14
    speedMinus.Parent = speedFrame
    local speedPlus = Instance.new("TextButton")
    speedPlus.Size = UDim2.new(0.15, 0, 0.7, 0)
    speedPlus.Position = UDim2.new(0.85, 0, 0.15, 0)
    speedPlus.Text = "+"
    speedPlus.BackgroundColor3 = C.bg3
    speedPlus.Font = Enum.Font.GothamBold
    speedPlus.TextSize = 14
    speedPlus.Parent = speedFrame
    speedMinus.MouseButton1Click:Connect(function() speedVal = math.max(32, speedVal - 1); speedLabel.Text = "Speed: "..speedVal; if speedHack then setSpeed() end end)
    speedPlus.MouseButton1Click:Connect(function() speedVal = math.min(80, speedVal + 1); speedLabel.Text = "Speed: "..speedVal; if speedHack then setSpeed() end end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0.35, 0, 0, 35)
    close.Position = UDim2.new(0.325, 0, 0, 90)
    close.Text = "CLOSE"
    close.TextColor3 = C.textDim
    close.BackgroundColor3 = C.bg3
    close.Font = Enum.Font.GothamBold
    close.TextSize = 13
    close.Parent = pop
    close.MouseButton1Click:Connect(function() pop:Destroy() end)
end

local function showNoCollisionSettings()
    local pop = Instance.new("Frame")
    pop.Size = UDim2.new(0, 320, 0, 100)
    pop.Position = UDim2.new(0.5, -160, 0.5, -50)
    pop.BackgroundColor3 = C.bg2
    pop.BackgroundTransparency = 0.1
    pop.BorderSizePixel = 1
    pop.BorderColor3 = C.accent
    pop.Parent = gui
    local popCorner = Instance.new("UICorner")
    popCorner.CornerRadius = UDim.new(0, 12)
    popCorner.Parent = pop
    local popTitle = Instance.new("TextLabel")
    popTitle.Size = UDim2.new(1, 0, 0, 40)
    popTitle.Text = "No Collision"
    popTitle.TextColor3 = C.accent
    popTitle.BackgroundColor3 = C.bg
    popTitle.Font = Enum.Font.GothamBold
    popTitle.TextSize = 16
    popTitle.Parent = pop
    
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(0.8, 0, 0, 30)
    info.Position = UDim2.new(0.1, 0, 0, 45)
    info.Text = "You can walk through players"
    info.TextColor3 = C.textDim
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.Gotham
    info.TextSize = 12
    info.Parent = pop
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0.35, 0, 0, 35)
    close.Position = UDim2.new(0.325, 0, 0, 80)
    close.Text = "CLOSE"
    close.TextColor3 = C.textDim
    close.BackgroundColor3 = C.bg3
    close.Font = Enum.Font.GothamBold
    close.TextSize = 13
    close.Parent = pop
    close.MouseButton1Click:Connect(function() pop:Destroy() end)
end

local function showKnockbackSettings()
    local pop = Instance.new("Frame")
    pop.Size = UDim2.new(0, 320, 0, 120)
    pop.Position = UDim2.new(0.5, -160, 0.5, -60)
    pop.BackgroundColor3 = C.bg2
    pop.BackgroundTransparency = 0.1
    pop.BorderSizePixel = 1
    pop.BorderColor3 = C.accent
    pop.Parent = gui
    local popCorner = Instance.new("UICorner")
    popCorner.CornerRadius = UDim.new(0, 12)
    popCorner.Parent = pop
    local popTitle = Instance.new("TextLabel")
    popTitle.Size = UDim2.new(1, 0, 0, 40)
    popTitle.Text = "Knockback"
    popTitle.TextColor3 = C.accent
    popTitle.BackgroundColor3 = C.bg
    popTitle.Font = Enum.Font.GothamBold
    popTitle.TextSize = 16
    popTitle.Parent = pop
    
    local powerFrame = Instance.new("Frame")
    powerFrame.Size = UDim2.new(0.8, 0, 0, 35)
    powerFrame.Position = UDim2.new(0.1, 0, 0, 45)
    powerFrame.BackgroundColor3 = C.bg
    powerFrame.Parent = pop
    local powerLabel = Instance.new("TextLabel")
    powerLabel.Size = UDim2.new(0.5, 0, 1, 0)
    powerLabel.Text = "Power: "..knockbackPower
    powerLabel.TextColor3 = C.text
    powerLabel.BackgroundTransparency = 1
    powerLabel.Font = Enum.Font.Gotham
    powerLabel.TextSize = 12
    powerLabel.Parent = powerFrame
    local powerMinus = Instance.new("TextButton")
    powerMinus.Size = UDim2.new(0.15, 0, 0.7, 0)
    powerMinus.Position = UDim2.new(0.7, 0, 0.15, 0)
    powerMinus.Text = "-"
    powerMinus.BackgroundColor3 = C.bg3
    powerMinus.Font = Enum.Font.GothamBold
    powerMinus.TextSize = 14
    powerMinus.Parent = powerFrame
    local powerPlus = Instance.new("TextButton")
    powerPlus.Size = UDim2.new(0.15, 0, 0.7, 0)
    powerPlus.Position = UDim2.new(0.85, 0, 0.15, 0)
    powerPlus.Text = "+"
    powerPlus.BackgroundColor3 = C.bg3
    powerPlus.Font = Enum.Font.GothamBold
    powerPlus.TextSize = 14
    powerPlus.Parent = powerFrame
    powerMinus.MouseButton1Click:Connect(function() knockbackPower = math.max(20, knockbackPower - 5); powerLabel.Text = "Power: "..knockbackPower end)
    powerPlus.MouseButton1Click:Connect(function() knockbackPower = math.min(100, knockbackPower + 5); powerLabel.Text = "Power: "..knockbackPower end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0.35, 0, 0, 35)
    close.Position = UDim2.new(0.325, 0, 0, 90)
    close.Text = "CLOSE"
    close.TextColor3 = C.textDim
    close.BackgroundColor3 = C.bg3
    close.Font = Enum.Font.GothamBold
    close.TextSize = 13
    close.Parent = pop
    close.MouseButton1Click:Connect(function() pop:Destroy() end)
end

-- Launcher by bio0n
local function showLauncher()
    local launcher = Instance.new("Frame")
    launcher.Size = UDim2.new(0, 400, 0, 300)
    launcher.Position = UDim2.new(0.5, -200, 0.5, -150)
    launcher.BackgroundColor3 = C.bg
    launcher.BackgroundTransparency = 0.1
    launcher.BorderSizePixel = 3
    launcher.BorderColor3 = C.accent
    launcher.Parent = gui
    local launcherCorner = Instance.new("UICorner")
    launcherCorner.CornerRadius = UDim.new(0, 20)
    launcherCorner.Parent = launcher
    
    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, 10, 1, 10)
    glow.Position = UDim2.new(0, -5, 0, -5)
    glow.BackgroundColor3 = C.accent
    glow.BackgroundTransparency = 0.8
    glow.BorderSizePixel = 0
    glow.Parent = launcher
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 25)
    glowCorner.Parent = glow
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.Text = "ENDIX LITE"
    title.TextColor3 = C.accent
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.Parent = launcher
    
    local author = Instance.new("TextLabel")
    author.Size = UDim2.new(1, 0, 0, 30)
    author.Position = UDim2.new(0, 0, 0, 85)
    author.Text = "by bio0n"
    author.TextColor3 = C.pink
    author.BackgroundTransparency = 1
    author.Font = Enum.Font.GothamBold
    author.TextSize = 18
    author.Parent = launcher
    
    local roflText = Instance.new("TextLabel")
    roflText.Size = UDim2.new(1, 0, 0, 50)
    roflText.Position = UDim2.new(0, 0, 0, 120)
    roflText.Text = "ROFL MODE"
    roflText.TextColor3 = C.yellow
    roflText.BackgroundTransparency = 1
    roflText.Font = Enum.Font.GothamBold
    roflText.TextSize = 16
    roflText.Parent = launcher
    
    local spinText = Instance.new("TextLabel")
    spinText.Size = UDim2.new(1, 0, 0, 30)
    spinText.Position = UDim2.new(0, 0, 0, 170)
    spinText.Text = "LOADING..."
    spinText.TextColor3 = C.textDim
    spinText.BackgroundTransparency = 1
    spinText.Font = Enum.Font.Gotham
    spinText.TextSize = 12
    spinText.Parent = launcher
    
    local dots = 0
    local spinConn
    spinConn = RS.Heartbeat:Connect(function()
        dots = (dots + 1) % 4
        local dotStr = string.rep(".", dots)
        spinText.Text = "LOADING" .. dotStr
    end)
    
    local launchBtn = Instance.new("TextButton")
    launchBtn.Size = UDim2.new(0.4, 0, 0, 45)
    launchBtn.Position = UDim2.new(0.3, 0, 0, 220)
    launchBtn.Text = "LAUNCH"
    launchBtn.TextColor3 = C.white
    launchBtn.BackgroundColor3 = C.accent
    launchBtn.Font = Enum.Font.GothamBold
    launchBtn.TextSize = 16
    launchBtn.BorderSizePixel = 0
    launchBtn.Parent = launcher
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 12)
    btnCorner.Parent = launchBtn
    
    launchBtn.MouseEnter:Connect(function()
        launchBtn.BackgroundColor3 = C.red
        launchBtn.Text = "CLICK"
    end)
    launchBtn.MouseLeave:Connect(function()
        launchBtn.BackgroundColor3 = C.accent
        launchBtn.Text = "LAUNCH"
    end)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.2, 0, 0, 30)
    closeBtn.Position = UDim2.new(0.4, 0, 0, 270)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = C.textDim
    closeBtn.BackgroundColor3 = C.bg3
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.BorderSizePixel = 1
    closeBtn.BorderColor3 = C.accent
    closeBtn.Parent = launcher
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        if spinConn then spinConn:Disconnect() end
        launcher:Destroy()
    end)
    
    launchBtn.MouseButton1Click:Connect(function()
        for i = 1, 3 do
            launchBtn.Text = string.rep("!", i) .. " GO " .. string.rep("!", i)
            task.wait(0.1)
        end
        launchBtn.Text = "READY"
        launchBtn.BackgroundColor3 = C.green
        
        local flash = Instance.new("Frame")
        flash.Size = UDim2.new(1, 0, 1, 0)
        flash.BackgroundColor3 = C.accent
        flash.BackgroundTransparency = 0.5
        flash.Parent = launcher
        flash.ZIndex = 10
        for i = 1, 5 do
            flash.BackgroundTransparency = 0.5 - i * 0.1
            task.wait(0.05)
        end
        flash:Destroy()
        
        task.wait(0.5)
        if spinConn then spinConn:Disconnect() end
        launcher:Destroy()
        
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(0, 280, 0, 45)
        msg.Position = UDim2.new(0.5, -140, 0.8, 0)
        msg.Text = "ENDIX LITE | by bio0n"
        msg.TextColor3 = C.green
        msg.BackgroundColor3 = C.bg
        msg.BackgroundTransparency = 0.2
        msg.Font = Enum.Font.GothamBold
        msg.TextSize = 13
        msg.BorderSizePixel = 1
        msg.BorderColor3 = C.accent
        msg.Parent = gui
        local msgCorner = Instance.new("UICorner")
        msgCorner.CornerRadius = UDim.new(0, 12)
        msgCorner.Parent = msg
        game:GetService("Debris"):AddItem(msg, 3)
    end)
end

-- Custom Teleport Input
local function showCustomTeleport()
    local pop = Instance.new("Frame")
    pop.Size = UDim2.new(0, 320, 0, 200)
    pop.Position = UDim2.new(0.5, -160, 0.5, -100)
    pop.BackgroundColor3 = C.bg2
    pop.BackgroundTransparency = 0.1
    pop.BorderSizePixel = 1
    pop.BorderColor3 = C.accent
    pop.Parent = gui
    local popCorner = Instance.new("UICorner")
    popCorner.CornerRadius = UDim.new(0, 12)
    popCorner.Parent = pop
    
    local popTitle = Instance.new("TextLabel")
    popTitle.Size = UDim2.new(1, 0, 0, 40)
    popTitle.Text = "Custom Teleport"
    popTitle.TextColor3 = C.accent
    popTitle.BackgroundColor3 = C.bg
    popTitle.Font = Enum.Font.GothamBold
    popTitle.TextSize = 16
    popTitle.Parent = pop
    
    local xBox = Instance.new("TextBox")
    xBox.Size = UDim2.new(0.25, 0, 0, 35)
    xBox.Position = UDim2.new(0.1, 0, 0, 50)
    xBox.PlaceholderText = "X"
    xBox.Text = "0"
    xBox.TextColor3 = C.text
    xBox.BackgroundColor3 = C.bg
    xBox.Font = Enum.Font.Gotham
    xBox.TextSize = 14
    xBox.Parent = pop
    
    local yBox = Instance.new("TextBox")
    yBox.Size = UDim2.new(0.25, 0, 0, 35)
    yBox.Position = UDim2.new(0.4, 0, 0, 50)
    yBox.PlaceholderText = "Y"
    yBox.Text = "5"
    yBox.TextColor3 = C.text
    yBox.BackgroundColor3 = C.bg
    yBox.Font = Enum.Font.Gotham
    yBox.TextSize = 14
    yBox.Parent = pop
    
    local zBox = Instance.new("TextBox")
    zBox.Size = UDim2.new(0.25, 0, 0, 35)
    zBox.Position = UDim2.new(0.7, 0, 0, 50)
    zBox.PlaceholderText = "Z"
    zBox.Text = "0"
    zBox.TextColor3 = C.text
    zBox.BackgroundColor3 = C.bg
    zBox.Font = Enum.Font.Gotham
    zBox.TextSize = 14
    zBox.Parent = pop
    
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0.35, 0, 0, 40)
    tpBtn.Position = UDim2.new(0.325, 0, 0, 100)
    tpBtn.Text = "TELEPORT"
    tpBtn.TextColor3 = C.white
    tpBtn.BackgroundColor3 = C.accent
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 14
    tpBtn.Parent = pop
    local tpCorner = Instance.new("UICorner")
    tpCorner.CornerRadius = UDim.new(0, 8)
    tpCorner.Parent = tpBtn
    
    tpBtn.MouseButton1Click:Connect(function()
        local x = tonumber(xBox.Text) or 0
        local y = tonumber(yBox.Text) or 5
        local z = tonumber(zBox.Text) or 0
        tpToCoords(x, y, z)
        pop:Destroy()
        
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(0, 250, 0, 35)
        msg.Position = UDim2.new(0.5, -125, 0.7, 0)
        msg.Text = "Teleported to "..x..", "..y..", "..z
        msg.TextColor3 = C.success
        msg.BackgroundColor3 = C.bg
        msg.BackgroundTransparency = 0.2
        msg.Font = Enum.Font.Gotham
        msg.TextSize = 11
        msg.BorderSizePixel = 1
        msg.BorderColor3 = C.accent
        msg.Parent = gui
        local msgCorner = Instance.new("UICorner")
        msgCorner.CornerRadius = UDim.new(0, 8)
        msgCorner.Parent = msg
        game:GetService("Debris"):AddItem(msg, 2)
    end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0.2, 0, 0, 30)
    close.Position = UDim2.new(0.4, 0, 0, 155)
    close.Text = "CLOSE"
    close.TextColor3 = C.textDim
    close.BackgroundColor3 = C.bg3
    close.Font = Enum.Font.GothamBold
    close.TextSize = 12
    close.Parent = pop
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = close
    close.MouseButton1Click:Connect(function() pop:Destroy() end)
end

-- MAIN MENU
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 500, 0, 500)
main.Position = UDim2.new(0.5, -250, 0.5, -250)
main.BackgroundColor3 = C.bg
main.BackgroundTransparency = 0.2
main.BorderSizePixel = 2
main.BorderColor3 = C.accent
main.Visible = false
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 55)
header.BackgroundColor3 = C.bg2
header.BackgroundTransparency = 0.3
header.Parent = main
local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.Text = "ENDIX LITE"
titleLabel.TextColor3 = C.accent
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 24
titleLabel.Parent = header

-- Tabs
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, 0, 0, 40)
tabFrame.Position = UDim2.new(0, 0, 0, 60)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = main
local tabs = {"COMBAT", "MOVEMENT", "EXTRA"}
local curTab = 1
local tabBtns = {}

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -20, 1, -120)
content.Position = UDim2.new(0, 10, 0, 105)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 10
content.ScrollBarImageColor3 = C.accent
content.Parent = main
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.Parent = content

for i, n in ipairs(tabs) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.33, 0, 1, 0)
    b.Position = UDim2.new((i-1)*0.33, 0, 0, 0)
    b.Text = n
    b.TextColor3 = i == 1 and C.accent or C.text
    b.BackgroundTransparency = 1
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Parent = tabFrame
    tabBtns[i] = b
end

-- Helper function for module creation
local function addModule(parent, name, varName, desc, settingsFunc, keyName)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0.95, 0, 0, 70)
    f.BackgroundColor3 = C.bg2
    f.BackgroundTransparency = 0.4
    f.Parent = parent
    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 10)
    fCorner.Parent = f
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.4, 0, 0, 25)
    l.Position = UDim2.new(0.05, 0, 0.1, 0)
    l.Text = name
    l.TextColor3 = C.text
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
    l.Parent = f
    
    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(0.4, 0, 0, 20)
    d.Position = UDim2.new(0.05, 0, 0.55, 0)
    d.Text = desc
    d.TextColor3 = C.textDim
    d.BackgroundTransparency = 1
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.Font = Enum.Font.Gotham
    d.TextSize = 9
    d.Parent = f
    
    local keyData = keybinds[varName]
    local keyNameStr = keyData and tostring(keyData.key):gsub("Enum.KeyCode.", "") or "?"
    local enabledIcon = keyData and keyData.enabled and "ON" or "OFF"
    local keyHint = Instance.new("TextLabel")
    keyHint.Size = UDim2.new(0.12, 0, 0, 18)
    keyHint.Position = UDim2.new(0.68, 0, 0.65, 0)
    keyHint.Text = enabledIcon.." ["..keyNameStr.."]"
    keyHint.TextColor3 = keyData and keyData.enabled and C.success or C.textDim
    keyHint.BackgroundTransparency = 1
    keyHint.Font = Enum.Font.Gotham
    keyHint.TextSize = 9
    keyHint.Parent = f
    
    local state = false
    if varName == "KillAura" then state = killAura
    elseif varName == "SpeedHack" then state = speedHack
    elseif varName == "InfiniteJump" then state = infiniteJump
    elseif varName == "NoCollision" then state = noCollision
    elseif varName == "Knockback" then state = knockback
    end
    
    local tog = Instance.new("TextButton")
    tog.Size = UDim2.new(0.1, 0, 0.5, 0)
    tog.Position = UDim2.new(0.6, 0, 0.2, 0)
    tog.Text = state and "ON" or "OFF"
    tog.TextColor3 = state and C.success or C.text
    tog.BackgroundColor3 = C.bg
    tog.Font = Enum.Font.GothamBold
    tog.TextSize = 11
    tog.BorderSizePixel = 1
    tog.BorderColor3 = C.accent
    tog.Parent = f
    local togCorner = Instance.new("UICorner")
    togCorner.CornerRadius = UDim.new(0, 8)
    togCorner.Parent = tog
    
    tog.MouseButton1Click:Connect(function()
        state = not state
        tog.Text = state and "ON" or "OFF"
        tog.TextColor3 = state and C.success or C.text
        if varName == "KillAura" then killAura = state; if state then startKillAura() else if killLoop then killLoop:Disconnect(); killLoop=nil end end
        elseif varName == "SpeedHack" then speedHack = state; setSpeed()
        elseif varName == "InfiniteJump" then infiniteJump = state; setInfiniteJump()
        elseif varName == "NoCollision" then noCollision = state; setNoCollision()
        elseif varName == "Knockback" then knockback = state; if state then startKnockback() else if knockbackLoop then knockbackLoop:Disconnect(); knockbackLoop=nil end end
        end
    end)
    
    if settingsFunc then
        local gear = Instance.new("TextButton")
        gear.Size = UDim2.new(0.08, 0, 0.5, 0)
        gear.Position = UDim2.new(0.82, 0, 0.2, 0)
        gear.Text = "⚙️"
        gear.TextColor3 = C.textDim
        gear.BackgroundColor3 = C.bg
        gear.Font = Enum.Font.GothamBold
        gear.TextSize = 14
        gear.BorderSizePixel = 1
        gear.BorderColor3 = C.accent
        gear.Parent = f
        local gearCorner = Instance.new("UICorner")
        gearCorner.CornerRadius = UDim.new(0, 8)
        gearCorner.Parent = gear
        gear.MouseButton1Click:Connect(settingsFunc)
    end
    
    local bindBtn = Instance.new("TextButton")
    bindBtn.Size = UDim2.new(0.08, 0, 0.5, 0)
    bindBtn.Position = UDim2.new(0.91, 0, 0.2, 0)
    bindBtn.Text = "🔗"
    bindBtn.TextColor3 = keyData and keyData.enabled and C.success or C.textDim
    bindBtn.BackgroundColor3 = C.bg
    bindBtn.Font = Enum.Font.GothamBold
    bindBtn.TextSize = 14
    bindBtn.BorderSizePixel = 1
    bindBtn.BorderColor3 = C.accent
    bindBtn.Parent = f
    local bindCorner = Instance.new("UICorner")
    bindCorner.CornerRadius = UDim.new(0, 8)
    bindCorner.Parent = bindBtn
    
    bindBtn.MouseButton1Click:Connect(function()
        local pop = Instance.new("Frame")
        pop.Size = UDim2.new(0, 280, 0, 140)
        pop.Position = UDim2.new(0.5, -140, 0.5, -70)
        pop.BackgroundColor3 = C.bg2
        pop.BorderSizePixel = 1
        pop.BorderColor3 = C.accent
        pop.Parent = gui
        local popCorner = Instance.new("UICorner")
        popCorner.CornerRadius = UDim.new(0, 12)
        popCorner.Parent = pop
        local popTitle = Instance.new("TextLabel")
        popTitle.Size = UDim2.new(1, 0, 0, 40)
        popTitle.Text = "Press any key for "..name
        popTitle.TextColor3 = C.accent
        popTitle.BackgroundColor3 = C.bg
        popTitle.Font = Enum.Font.GothamBold
        popTitle.TextSize = 14
        popTitle.Parent = pop
        
        local removeBtn = Instance.new("TextButton")
        removeBtn.Size = UDim2.new(0.6, 0, 0, 35)
        removeBtn.Position = UDim2.new(0.2, 0, 0, 50)
        removeBtn.Text = "Remove Bind"
        removeBtn.TextColor3 = C.red
        removeBtn.BackgroundColor3 = C.bg
        removeBtn.Font = Enum.Font.GothamBold
        removeBtn.TextSize = 12
        removeBtn.Parent = pop
        local removeCorner = Instance.new("UICorner")
        removeCorner.CornerRadius = UDim.new(0, 8)
        removeCorner.Parent = removeBtn
        removeBtn.MouseButton1Click:Connect(function()
            keybinds[varName].key = nil
            keyHint.Text = "OFF [?]"
            keyHint.TextColor3 = C.textDim
            bindBtn.TextColor3 = C.textDim
            pop:Destroy()
        end)
        
        local conn
        conn = UIS.InputBegan:Connect(function(inp)
            if inp.KeyCode ~= Enum.KeyCode.Unknown then
                keybinds[varName].key = inp.KeyCode
                local newKeyName = tostring(inp.KeyCode):gsub("Enum.KeyCode.", "")
                keyHint.Text = "ON ["..newKeyName.."]"
                keyHint.TextColor3 = C.success
                bindBtn.TextColor3 = C.success
                conn:Disconnect()
                pop:Destroy()
            end
        end)
        task.wait(5)
        if conn and conn.Connected then conn:Disconnect(); pop:Destroy() end
    end)
    
    return f
end

local function updateContent()
    for _, c in ipairs(content:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    
    if curTab == 1 then -- COMBAT
        addModule(content, "KILL AURA", "KillAura", "Mode: "..killMode, showKillAuraSettings, "KillAura")
        
    elseif curTab == 2 then -- MOVEMENT
        addModule(content, "SPEED HACK", "SpeedHack", "Speed: "..speedVal, showSpeedSettings, "SpeedHack")
        addModule(content, "INFINITE JUMP", "InfiniteJump", "Jump infinitely", nil, "InfiniteJump")
        
    elseif curTab == 3 then -- EXTRA
        addModule(content, "NO COLLISION", "NoCollision", "Walk through players", showNoCollisionSettings, "NoCollision")
        addModule(content, "KNOCKBACK", "Knockback", "Push players away", showKnockbackSettings, "Knockback")
        
        -- Launcher by bio0n
        local launcherFrame = Instance.new("Frame")
        launcherFrame.Size = UDim2.new(0.95, 0, 0, 80)
        launcherFrame.BackgroundColor3 = C.bg2
        launcherFrame.BackgroundTransparency = 0.4
        launcherFrame.Parent = content
        local launcherCorner = Instance.new("UICorner")
        launcherCorner.CornerRadius = UDim.new(0, 12)
        launcherCorner.Parent = launcherFrame
        
        local launcherTitle = Instance.new("TextLabel")
        launcherTitle.Size = UDim2.new(0.6, 0, 0, 30)
        launcherTitle.Position = UDim2.new(0.05, 0, 0.1, 0)
        launcherTitle.Text = "LAUNCHER by bio0n"
        launcherTitle.TextColor3 = C.pink
        launcherTitle.BackgroundTransparency = 1
        launcherTitle.TextXAlignment = Enum.TextXAlignment.Left
        launcherTitle.Font = Enum.Font.GothamBold
        launcherTitle.TextSize = 16
        launcherTitle.Parent = launcherFrame
        
        local launcherDesc = Instance.new("TextLabel")
        launcherDesc.Size = UDim2.new(0.6, 0, 0, 20)
        launcherDesc.Position = UDim2.new(0.05, 0, 0.55, 0)
        launcherDesc.Text = "ROFL MODE"
        launcherDesc.TextColor3 = C.yellow
        launcherDesc.BackgroundTransparency = 1
        launcherDesc.TextXAlignment = Enum.TextXAlignment.Left
        launcherDesc.Font = Enum.Font.Gotham
        launcherDesc.TextSize = 10
        launcherDesc.Parent = launcherFrame
        
        local launchBtn = Instance.new("TextButton")
        launchBtn.Size = UDim2.new(0.25, 0, 0.5, 0)
        launchBtn.Position = UDim2.new(0.7, 0, 0.25, 0)
        launchBtn.Text = "LAUNCH"
        launchBtn.TextColor3 = C.white
        launchBtn.BackgroundColor3 = C.accent
        launchBtn.Font = Enum.Font.GothamBold
        launchBtn.TextSize = 12
        launchBtn.BorderSizePixel = 0
        launchBtn.Parent = launcherFrame
        local launchBtnCorner = Instance.new("UICorner")
        launchBtnCorner.CornerRadius = UDim.new(0, 8)
        launchBtnCorner.Parent = launchBtn
        launchBtn.MouseButton1Click:Connect(showLauncher)
        
        -- TELEPORT SECTION
        local tpFrame = Instance.new("Frame")
        tpFrame.Size = UDim2.new(0.95, 0, 0, 220)
        tpFrame.BackgroundColor3 = C.bg2
        tpFrame.BackgroundTransparency = 0.4
        tpFrame.Parent = content
        local tpCorner = Instance.new("UICorner")
        tpCorner.CornerRadius = UDim.new(0, 12)
        tpCorner.Parent = tpFrame
        
        local tpTitle = Instance.new("TextLabel")
        tpTitle.Size = UDim2.new(1, 0, 0, 30)
        tpTitle.Position = UDim2.new(0.05, 0, 0, 0)
        tpTitle.Text = "TELEPORT"
        tpTitle.TextColor3 = C.accent
        tpTitle.BackgroundTransparency = 1
        tpTitle.Font = Enum.Font.GothamBold
        tpTitle.TextSize = 16
        tpTitle.Parent = tpFrame
        
        local y = 35
        local function addTpBtn(text, func)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.28, 0, 0, 32)
            btn.Position = UDim2.new(0.05, 0, 0, y)
            btn.Text = text
            btn.TextColor3 = C.text
            btn.BackgroundColor3 = C.bg
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 11
            btn.BorderSizePixel = 1
            btn.BorderColor3 = C.accent
            btn.Parent = tpFrame
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = btn
            btn.MouseButton1Click:Connect(func)
            y = y + 38
        end
        
        addTpBtn("Save Pos", function() 
            local c = LP.Character 
            if c then 
                local r = c:FindFirstChild("HumanoidRootPart") 
                if r then 
                    savedPos = r.Position
                    local msg = Instance.new("TextLabel")
                    msg.Size = UDim2.new(0, 200, 0, 30)
                    msg.Position = UDim2.new(0.5, -100, 0.7, 0)
                    msg.Text = "Position saved!"
                    msg.TextColor3 = C.success
                    msg.BackgroundColor3 = C.bg
                    msg.BackgroundTransparency = 0.2
                    msg.Font = Enum.Font.Gotham
                    msg.TextSize = 11
                    msg.BorderSizePixel = 1
                    msg.BorderColor3 = C.accent
                    msg.Parent = gui
                    local msgCorner = Instance.new("UICorner")
                    msgCorner.CornerRadius = UDim.new(0, 8)
                    msgCorner.Parent = msg
                    game:GetService("Debris"):AddItem(msg, 1.5)
                end 
            end 
        end)
        
        addTpBtn("Load Pos", function() 
            if savedPos then 
                tpToPos(savedPos)
                local msg = Instance.new("TextLabel")
                msg.Size = UDim2.new(0, 200, 0, 30)
                msg.Position = UDim2.new(0.5, -100, 0.7, 0)
                msg.Text = "Loaded saved position!"
                msg.TextColor3 = C.success
                msg.BackgroundColor3 = C.bg
                msg.BackgroundTransparency = 0.2
                msg.Font = Enum.Font.Gotham
                msg.TextSize = 11
                msg.BorderSizePixel = 1
                msg.BorderColor3 = C.accent
                msg.Parent = gui
                local msgCorner = Instance.new("UICorner")
                msgCorner.CornerRadius = UDim.new(0, 8)
                msgCorner.Parent = msg
                game:GetService("Debris"):AddItem(msg, 1.5)
            end 
        end)
        
        for _, point in ipairs(teleportPoints) do 
            addTpBtn(point.name, function() tpToCoords(point.x, point.y, point.z) end)
        end
        
        addTpBtn("Custom XYZ", showCustomTeleport)
        
        tpFrame.Size = UDim2.new(0.95, 0, 0, y + 10)
    end
    
    content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end

for i, b in ipairs(tabBtns) do
    b.MouseButton1Click:Connect(function()
        curTab = i
        for j, btn in ipairs(tabBtns) do btn.TextColor3 = j == i and C.accent or C.text end
        updateContent()
    end)
end

local close = Instance.new("TextButton")
close.Size = UDim2.new(0.1, 0, 0, 40)
close.Position = UDim2.new(0.45, 0, 0, 450)
close.Text = "CLOSE"
close.TextColor3 = C.text
close.BackgroundColor3 = C.bg3
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.BorderSizePixel = 1
close.BorderColor3 = C.accent
close.Parent = main
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = close
close.MouseButton1Click:Connect(function() main.Visible = false end)

UIS.InputBegan:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.Insert then
        main.Visible = not main.Visible
        if main.Visible then updateContent() end
    end
end)

updateContent()
print("Endix Lite Loaded! Press INSERT")
print("Features: Kill Aura (Smooth/Rage/Aimbot), Speed, Infinite Jump, No Collision, Knockback, Teleport")
print("by bio0n")