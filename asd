local ANIMATIONS = {
	Idle = {id = "rbxassetid://121514984215513", track = nil, shouldLoop = true},
	Walk = {id = "rbxassetid://121514984215513", track = nil, shouldLoop = true},
	Run = {id = "rbxassetid://123726206807935", track = nil, shouldLoop = true},
	SuperRun = {id = "rbxassetid://82114565363304", track = nil, shouldLoop = true},
	Jump = {id = "rbxassetid://71459504024777", track = nil, shouldLoop = false},
	Fall = {id = "rbxassetid://77532784364790", track = nil, shouldLoop = true},
	PeelCharge = {id = "rbxassetid://82114565363304", track = nil, shouldLoop = true}
}

local function loadAsset(id)
	local ok, objects = pcall(game.GetObjects, game, "rbxassetid://" .. id)
	if not ok or not objects or #objects == 0 then return nil end
	return objects[1]:Clone()
end

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character, root, humanoid

local function setupCharacter(char)
	character = char
	root = char:WaitForChild("HumanoidRootPart")
	humanoid = char:WaitForChild("Humanoid")
end
if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

-- ====================== HOOK ABILITY (TUFF + Made by the goat itsjustyumy.) ======================
local hookCooldown = false
local grappling = false
local pulling = false
local cancelPull = false
local cooldownTime = 4
local maxDistance = 250
local hookPart, tipPart, beam, rope, rootAttachment, hookAttachment
local hookCooldownLbl = nil


local footAttachment = Instance.new("Attachment")
footAttachment.Name = "FootAttachment"
footAttachment.Position = Vector3.new(0, -2, 0)
footAttachment.Parent = root or workspace  

local dustEmitter = Instance.new("ParticleEmitter")
dustEmitter.Texture = "rbxassetid://363622340"
dustEmitter.Color = ColorSequence.new(Color3.fromRGB(150,150,150))
dustEmitter.Rate = 50
dustEmitter.Lifetime = NumberRange.new(0.3,0.5)
dustEmitter.Speed = NumberRange.new(2,4)
dustEmitter.Rotation = NumberRange.new(0,360)
dustEmitter.RotSpeed = NumberRange.new(-180,180)
dustEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,0)})
dustEmitter.Enabled = false
dustEmitter.Parent = footAttachment

local windEmitter = Instance.new("ParticleEmitter")
windEmitter.Texture = "rbxassetid://243660364"
windEmitter.Color = ColorSequence.new(Color3.fromRGB(200,200,255))
windEmitter.Rate = 80
windEmitter.Lifetime = NumberRange.new(0.2,0.4)
windEmitter.Speed = NumberRange.new(10,15)
windEmitter.VelocitySpread = 180
windEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(1,0)})
windEmitter.Enabled = false
windEmitter.Parent = root or workspace

local function startParticles()
	dustEmitter.Enabled = true
	windEmitter.Enabled = true
end

local function stopParticles()
	dustEmitter.Enabled = false
	windEmitter.Enabled = false
end


local function flashEffect(char, duration, color)
	if not char then return end
	local highlight = Instance.new("Highlight")
	highlight.Adornee = char
	highlight.OutlineColor = Color3.fromRGB(255,255,255)
	highlight.FillColor = color
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = char

	local fillTween = TweenService:Create(highlight, TweenInfo.new(duration/2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FillTransparency = 0})
	fillTween:Play()
	fillTween.Completed:Connect(function()
		TweenService:Create(highlight, TweenInfo.new(duration/2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FillTransparency = 1}):Play()
	end)

	local outlineTween = TweenService:Create(highlight, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {OutlineTransparency = 1})
	outlineTween:Play()
	outlineTween.Completed:Connect(function()
		if highlight then highlight:Destroy() end
	end)
end

local function getNearestPlayer()
	local nearest, shortest = nil, math.huge
	if not root then return nil end
	local myPos = root.Position
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (plr.Character.HumanoidRootPart.Position - myPos).Magnitude
			if dist < shortest and dist <= maxDistance then
				shortest = dist
				nearest = plr
			end
		end
	end
	return nearest
end

local function shootGrapple()
	if not root or grappling then return end
	local target = getNearestPlayer()
	if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local targetPos = target.Character.HumanoidRootPart.Position
	local origin = root.Position
	local direction = (targetPos - origin).Unit

	
	hookPart = Instance.new("Part")
	hookPart.Size = Vector3.new(0.7,0.7,0.7)
	hookPart.Position = origin
	hookPart.Anchored = true
	hookPart.CanCollide = false
	hookPart.Transparency = 1
	hookPart.Parent = workspace

	tipPart = Instance.new("Part")
	tipPart.Size = Vector3.new(0.5,0.5,0.5)
	tipPart.Position = origin
	tipPart.Anchored = true
	tipPart.CanCollide = false
	tipPart.Color = Color3.fromRGB(255,255,255)
	tipPart.Parent = workspace

	rootAttachment = Instance.new("Attachment", root)
	hookAttachment = Instance.new("Attachment", tipPart)

	
	local trailAttachment0 = Instance.new("Attachment"); trailAttachment0.Position = Vector3.new(0,0,0); trailAttachment0.Parent = tipPart
	local trailAttachment1 = Instance.new("Attachment"); trailAttachment1.Position = Vector3.new(0,0,-1.5); trailAttachment1.Parent = tipPart
	local trail = Instance.new("Trail")
	trail.Attachment0 = trailAttachment0
	trail.Attachment1 = trailAttachment1
	trail.Lifetime = 0.5
	trail.Color = ColorSequence.new(Color3.fromRGB(255,255,255))
	trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.3,0.7),NumberSequenceKeypoint.new(0.6,0.4),NumberSequenceKeypoint.new(1,0.05)})
	trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.7,0.1),NumberSequenceKeypoint.new(1,1)})
	trail.MinLength = 0.1
	trail.FaceCamera = true
	trail.Parent = tipPart

	beam = Instance.new("Beam")
	beam.Attachment0 = rootAttachment
	beam.Attachment1 = hookAttachment
	beam.Width0 = 0.15
	beam.Width1 = 0.15
	beam.Color = ColorSequence.new(Color3.new(0,0,0))
	beam.Transparency = NumberSequence.new(0)
	beam.FaceCamera = true
	beam.Parent = root

	flashEffect(character, 0.4, Color3.fromRGB(173,216,230))

	local velocity = direction * 140 + Vector3.new(0,60,0)
	local gravity = Vector3.new(0,-workspace.Gravity,0)
	local pos = origin
	local hitSomething = false

	while true do
		local dt = task.wait()
		velocity += gravity * dt
		local newPos = pos + velocity * dt
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {character}
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		local result = workspace:Raycast(pos, newPos-pos, rayParams)

		if result and result.Instance.CanCollide then
			hookPart.Position = result.Position
			tipPart.Position = result.Position
			hitSomething = true
			flashEffect(character, 0.4, Color3.fromRGB(255,255,255))
			break
		end

		pos = newPos
		hookPart.Position = pos
		tipPart.Position = pos
		if (pos - origin).Magnitude > maxDistance then break end
	end

	if not hitSomething then
		flashEffect(character, 0.6, Color3.fromRGB(144,238,144))
	end

	rope = Instance.new("RopeConstraint")
	rope.Attachment0 = rootAttachment
	rope.Attachment1 = hookAttachment
	rope.Length = (root.Position - hookPart.Position).Magnitude
	rope.Visible = false
	rope.Parent = root
	
	if hookPart then hookPart:Destroy() hookPart = nil end
	if tipPart then tipPart:Destroy() tipPart = nil end
	

	grappling = true
end

local function pullPlayer()
	if not hookPart or not root then return end
	cancelPull = false
	startParticles()

	local forceAttachment = Instance.new("Attachment", root)
	local vectorForce = Instance.new("VectorForce")
	vectorForce.Attachment0 = forceAttachment
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.Parent = root

	local forcePower = 4500
	local maxSpeed = 80

	while true do
		if cancelPull then break end
		
		local distance = (hookPart.Position - root.Position).Magnitude
		if distance <= 6 then
			flashEffect(character, 0.6, Color3.fromRGB(144,238,144))
			break
		end

		local dir = (hookPart.Position - root.Position).Unit
		local speed = root.AssemblyLinearVelocity.Magnitude
		
		if speed < maxSpeed then
			vectorForce.Force = dir * forcePower
		else
			vectorForce.Force = Vector3.new(0,0,0)
		end
		
		task.wait()
	end

	if vectorForce then vectorForce:Destroy() end
	if forceAttachment then forceAttachment:Destroy() end

	stopParticles()
	removeHook()   
end

local function removeHook()
	cancelPull = true
	stopParticles()

	
	if hookPart then 
		hookPart:Destroy() 
		hookPart = nil 
	end
	if tipPart then 
		tipPart:Destroy() 
		tipPart = nil 
	end
	if beam then 
		beam:Destroy() 
		beam = nil 
	end
	if rope then 
		rope:Destroy() 
		rope = nil 
	end
	if rootAttachment then 
		rootAttachment:Destroy() 
		rootAttachment = nil 
	end
	if hookAttachment then 
		hookAttachment:Destroy() 
		hookAttachment = nil 
	end

	
	task.spawn(startHookCooldown)

	
	grappling = false
	pulling = false
end

local function startHookCooldown()
	hookCooldown = true
	for i = cooldownTime, 0.1, -0.1 do
		if hookCooldownLbl then hookCooldownLbl.Text = string.format("%.1f", i) end
		task.wait(0.1)
	end
	if hookCooldownLbl then hookCooldownLbl.Text = "" end
	hookCooldown = false
end

local function activateHook()
	if hookCooldown then return end
	shootGrapple()
	task.wait(0.3)
	pullPlayer()
end

local function playSound(id, parent, volume)
    if not parent then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(id)
    sound.Volume = volume or 1
    sound.Parent = parent
    
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

    local CONFIG = {
        HitboxSize = Vector3.new(10, 10, 10),  
        Transparency = 1,                    
        TargetAnimationId = "122414915357020"  
    }

    local function getNumericAnimationId(assetId)
        return tostring(assetId):match("%d+")
    end

    local trackedPlayers = {}

    local function isPlayingTargetAnimation(player)
        if not player or not player.Character then return false end
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        local animator = humanoid.Animator
        if not animator then return false end

        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            local anim = track.Animation
            if anim and getNumericAnimationId(anim.AnimationId) == CONFIG.TargetAnimationId then
                return true
            end
        end
        return false
    end

   
    local function createHitboxForTarget(targetPlayer)
        if trackedPlayers[targetPlayer] then return end 

        local hitbox = Instance.new("Part")
        hitbox.Size = CONFIG.HitboxSize
        hitbox.Transparency = CONFIG.Transparency
        hitbox.Anchored = true
        hitbox.CanCollide = false                     
        hitbox.Material = Enum.Material.Neon
        hitbox.BrickColor = BrickColor.new("Bright red")
        hitbox.Parent = Workspace

        
        local data = {
            hitbox = hitbox,
            teleportActive = false,                    
            cooldownActive = false,                    
            teleportLoop = nil,
            touchConnection = nil,
            touchEndConnection = nil,
            followLoop = nil                            
        }
        
        data.touchConnection = hitbox.Touched:Connect(function(part)
            if part.Parent == LocalPlayer.Character then
                if not data.cooldownActive then
                    data.teleportActive = true
                    
                    if not data.teleportLoop then
                        data.teleportLoop = RunService.Heartbeat:Connect(function()
                            if data.teleportActive and targetPlayer and targetPlayer.Character then
                                local localChar = LocalPlayer.Character
                                local targetChar = targetPlayer.Character
                                if localChar and targetChar then
                                    local localRoot = localChar:FindFirstChild("HumanoidRootPart") or localChar.PrimaryPart
                                    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar.PrimaryPart
                                    if localRoot and targetRoot then
                                        localRoot.CFrame = targetRoot.CFrame
                                    end
                                end
                            end
                        end)
                    end
                end
            end
        end)

        data.touchEndConnection = hitbox.TouchEnded:Connect(function(part)
            
        end)

        trackedPlayers[targetPlayer] = data

        spawn(function()
            while trackedPlayers[targetPlayer] and targetPlayer.Character do
                local root = targetPlayer.Character:FindFirstChild("HumanoidRootPart") or targetPlayer.Character.PrimaryPart
                if root then
                    hitbox.CFrame = root.CFrame
                end
                wait(0.03)
            end
        end)
    end

    
    local function removeHitboxForTarget(targetPlayer)
        local data = trackedPlayers[targetPlayer]
        if data then
            if data.hitbox then data.hitbox:Destroy() end
            if data.teleportLoop then data.teleportLoop:Disconnect() end
            if data.touchConnection then data.touchConnection:Disconnect() end
            if data.touchEndConnection then data.touchEndConnection:Disconnect() end
            trackedPlayers[targetPlayer] = nil
        end
    end

    
    local function updateTracking()
        
        for player, data in pairs(trackedPlayers) do
            if not isPlayingTargetAnimation(player) then
                removeHitboxForTarget(player)
            end
        end

        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and isPlayingTargetAnimation(player) then
                if not trackedPlayers[player] then
                    createHitboxForTarget(player)
                end
            end
        end
    end

    
    RunService.Heartbeat:Connect(updateTracking)

    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Space then
            for player, data in pairs(trackedPlayers) do
                if data.teleportActive and not data.cooldownActive then
                    

                    local character = LocalPlayer.Character
                    if character then
                        

                        local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
                        if root and data.hitbox then
                            

                            local localPos = data.hitbox.CFrame:PointToObjectSpace(root.Position)
                            local halfSize = data.hitbox.Size / 2
                            if math.abs(localPos.X) <= halfSize.X and
                               math.abs(localPos.Y) <= halfSize.Y and
                               math.abs(localPos.Z) <= halfSize.Z then
                                
                                data.teleportActive = false
                                data.cooldownActive = true
                                task.delay(1, function()
                                    if trackedPlayers[player] then
                                        data.cooldownActive = false
                                        
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)

    player.CharacterRemoving:Connect(function()
        for plr, data in pairs(trackedPlayers) do
            removeHitboxForTarget(plr)
        end
    end)

    print("sonic peelout for metal loaded : " .. CONFIG.TargetAnimationId)
    print("Touch sonic to start teleport like an chud. Press SPACE to get out of the peelout for 1 secound.")


local Players = game:GetService("Players")
local player = Players.LocalPlayer

player.CharacterAdded:Connect(function()
    task.defer(function()
        local src = script.Source
        local new = Instance.new("LocalScript")
        new.Name = script.Name
        new.Source = src
        new.Parent = player:WaitForChild("PlayerGui")
    end)
end)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local MAX_SPEEDCAP = 90
local ACCELERATION = 60
local DECELERATION = 650
local VERTICAL_BOOST = 0.14
local FLY = {
    MaxMeter            = 1000,
    RegenDelay          = 2.9,
    DrainIdle           = 100 / 2.6,
    DrainFast           = 100 / 3.9,
    HighSpeedMultiplier = 4,
    RegenRate           = 100.8
}

local FLY_ANIMATION_ID   = "rbxassetid://77532784364790"  
local STAMINA_FULL_SOUND = "rbxassetid://7547436144"      


local UI_CONFIG = {
    ImageFrameSize     = UDim2.new(0, 60, 0, 210),
    StaminaBarSize     = UDim2.new(0, 170, 0, 20),
    StaminaBarPosition = UDim2.new(0, -57, 0, 90),
    FadeSpeed          = 5,

    
    StudsOffset        = Vector3.new(3, 2, 0),
    MaxDistance        = 200,
}

local flyMeter    = FLY.MaxMeter
local flying      = false
local flyVelocity = Vector3.new(0, 0, 0)
local regenLocked = false
local jumpHeld    = false

local hasDrained      = false
local wasFullLastTick = true  

local bv, bg, highlight, windSfx
local flyConn
local flyAnimTrack

local flyGui = Instance.new("BillboardGui")
flyGui.Name         = "FlyMeter"
flyGui.Adornee      = root
flyGui.AlwaysOnTop  = true
flyGui.MaxDistance  = UI_CONFIG.MaxDistance
flyGui.Size         = UI_CONFIG.ImageFrameSize
flyGui.StudsOffset  = UI_CONFIG.StudsOffset
flyGui.ResetOnSpawn = false
flyGui.Parent       = player.PlayerGui

local anchorFrame = Instance.new("Frame")
anchorFrame.Name                  = "AnchorFrame"
anchorFrame.AnchorPoint           = Vector2.new(0.5, 0.5)
anchorFrame.Position              = UDim2.new(0.5, 0, 0.5, 0)
anchorFrame.Size                  = UDim2.new(1, 0, 1, 0)
anchorFrame.BackgroundTransparency = 1
anchorFrame.Parent                = flyGui

local imageLabel = Instance.new("ImageLabel")
imageLabel.Name               = "FlyBarImage"
imageLabel.Size               = UDim2.new(1, 0, 1, 0)
imageLabel.Position           = UDim2.new(0, 0, 0, 0)
imageLabel.BackgroundTransparency = 1
imageLabel.Image              = "rbxassetid://93111832921348"
imageLabel.ImageTransparency  = 1          
imageLabel.ScaleType          = Enum.ScaleType.Stretch
imageLabel.ZIndex             = 2
imageLabel.Parent             = anchorFrame


local staminaBg = Instance.new("Frame")
staminaBg.Name                   = "StaminaBg"
staminaBg.Size                   = UI_CONFIG.StaminaBarSize
staminaBg.Position               = UI_CONFIG.StaminaBarPosition
staminaBg.BackgroundColor3       = Color3.fromRGB(25, 0, 0)
staminaBg.BackgroundTransparency = 1        
staminaBg.BorderSizePixel        = 0
staminaBg.Rotation               = -90
staminaBg.ClipsDescendants       = true
staminaBg.ZIndex                 = 1
staminaBg.Parent                 = anchorFrame

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(0.3, 0)
bgCorner.Parent       = staminaBg


local staminaFill = Instance.new("Frame")
staminaFill.Name                   = "StaminaFill"
staminaFill.AnchorPoint            = Vector2.new(0, 0)
staminaFill.Size                   = UDim2.new(1, 0, 1, 0)
staminaFill.Position               = UDim2.new(0, 0, 0, 0)
staminaFill.BackgroundColor3       = Color3.fromRGB(139, 0, 0)
staminaFill.BackgroundTransparency = 1     
staminaFill.BorderSizePixel        = 0
staminaFill.ZIndex                 = 1
staminaFill.Parent                 = staminaBg



local staminaFullSfx = Instance.new("Sound")
staminaFullSfx.Name    = "StaminaFullSfx"
staminaFullSfx.SoundId = STAMINA_FULL_SOUND
staminaFullSfx.Volume  = 0.6
staminaFullSfx.Parent  = root

local function updateFlyBar()
    local pct = math.clamp(flyMeter / FLY.MaxMeter, 0, 1)
    staminaFill.Size = UDim2.new(pct, 0, 1, 0)

    
    if flyMeter < FLY.MaxMeter then
        hasDrained = true
    end

    
    local isFull = (flyMeter >= FLY.MaxMeter)
    if hasDrained and isFull and not wasFullLastTick then
        staminaFullSfx:Play()
        hasDrained = false  
    end
    wasFullLastTick = isFull
end

updateFlyBar()

RunService.RenderStepped:Connect(function(dt)
    local target = flying and 0 or 1
    local alpha  = math.clamp(dt * UI_CONFIG.FadeSpeed, 0, 1)

    imageLabel.ImageTransparency        = imageLabel.ImageTransparency        + (target - imageLabel.ImageTransparency)        * alpha
    staminaBg.BackgroundTransparency    = staminaBg.BackgroundTransparency    + (target - staminaBg.BackgroundTransparency)    * alpha
    staminaFill.BackgroundTransparency  = staminaFill.BackgroundTransparency  + (target - staminaFill.BackgroundTransparency)  * alpha
end)

local function startCyanEffect()
    if highlight then highlight:Destroy() end
    highlight = Instance.new("Highlight")
    highlight.Adornee      = char
    highlight.FillColor    = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(139, 0, 0)
    highlight.Parent       = char
end

local function stopCyanEffect()
    if highlight then
        highlight:Destroy()
        highlight = nil
    end
end

local function flyCancel()
    if not flying then return end
    flying = false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if bv      then bv:Destroy();         bv      = nil end
    if bg      then bg:Destroy();         bg      = nil end
    if windSfx then windSfx:Stop(); windSfx:Destroy(); windSfx = nil end
    stopCyanEffect()

    if flyAnimTrack then
        flyAnimTrack:Stop()
        flyAnimTrack = nil
    end

    flyVelocity = Vector3.new(0, 0, 0)
end

local function flyStart()
    if flying or flyMeter <= 0 then return end
    flying = true
    flyVelocity = Vector3.new(0, 0, 0)

    local sfx = Instance.new("Sound")
    sfx.SoundId = "rbxassetid://1295448103"
    sfx.Volume  = 0.8
    sfx.Parent  = root
    sfx:Play()
    task.delay(3, function() sfx:Destroy() end)

    windSfx = Instance.new("Sound")
    windSfx.SoundId = "rbxassetid://87629646373295"
    windSfx.Looped  = true
    windSfx.Volume  = 0.4
    windSfx.Parent  = root
    windSfx:Play()

    startCyanEffect()

    local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")
    local anim = Instance.new("Animation")
    anim.AnimationId = FLY_ANIMATION_ID
    local success, track = pcall(function()
        return animator:LoadAnimation(anim)
    end)
    if success and track then
        flyAnimTrack = track
        flyAnimTrack:Play()
    else
        warn("SilverFlight: Could not load animation with ID", FLY_ANIMATION_ID)
    end

    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.new()
    bv.Parent   = root

    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P         = 1e4
    bg.D         = 500
    bg.CFrame    = root.CFrame
    bg.Parent    = root

    flyConn = RunService.RenderStepped:Connect(function(dt)
        if not flying then return end
        local cam  = workspace.CurrentCamera
        local move = Vector3.new()

        if UserInputService.KeyboardEnabled then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end
        else
            local dir = humanoid.MoveDirection
            if dir.Magnitude > 0 then move = dir end
        end

        local targetVelocity
        if move.Magnitude > 0 then
            targetVelocity = move.Unit * MAX_SPEEDCAP + Vector3.new(0, MAX_SPEEDCAP * VERTICAL_BOOST, 0)
        else
            targetVelocity = Vector3.new(0, 0, 0)
        end

        local accel = (move.Magnitude > 0 and ACCELERATION or DECELERATION)
        flyVelocity = flyVelocity:Lerp(targetVelocity, math.clamp(accel * dt / MAX_SPEEDCAP, 0, 1))
        if flyVelocity ~= flyVelocity then flyVelocity = Vector3.new(0, 0, 0) end

        bv.Velocity = flyVelocity
        bg.CFrame   = cam.CFrame

        local speedRatio = math.clamp(flyVelocity.Magnitude / MAX_SPEEDCAP, 0, 1)
        local drain = FLY.DrainIdle + (FLY.DrainFast - FLY.DrainIdle) * speedRatio

        if flyVelocity.Magnitude > 30 then
            drain *= FLY.HighSpeedMultiplier
        end

        flyMeter = math.max(flyMeter - drain * dt, 0)
        updateFlyBar()

        if flyMeter <= 0 then
            flyCancel()
            regenLocked = true
            task.delay(FLY.RegenDelay, function() regenLocked = false end)
        end
    end)
end

task.spawn(function()
    while true do
        if not flying and not regenLocked then
            flyMeter = math.min(flyMeter + FLY.RegenRate, FLY.MaxMeter)
            updateFlyBar()
        end
        task.wait(0.3)
    end
end)



if UserInputService.KeyboardEnabled then
    UserInputService.InputBegan:Connect(function(i, g)
        if g then return end
        if i.KeyCode == Enum.KeyCode.Space then
            jumpHeld = true
            task.delay(0.3, function()
                if jumpHeld and not flying and flyMeter > 0 then flyStart() end
            end)
        end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if i.KeyCode == Enum.KeyCode.Space then
            jumpHeld = false
            flyCancel()
        end
    end)
end

if isMobile then
    local btn = Instance.new("ImageButton")
    btn.Parent               = player.PlayerGui
    btn.Size                 = UDim2.new(0, 50, 0, 50)
    btn.Position             = UDim2.new(1, -60, 0.6, 0)
    btn.BackgroundTransparency = 1
    btn.Image                = "rbxassetid://72410974345101"
    btn.ZIndex               = 10

    local label = Instance.new("TextLabel")
    label.Parent               = btn
    label.Size                 = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextScaled           = true
    label.Font                 = Enum.Font.GothamBold
    label.TextColor3           = Color3.fromRGB(0, 150, 255)
    label.ZIndex               = 11

    local function update() label.Text = flying and "Fly ON" or "Fly OFF" end
    update()

    btn.InputBegan:Connect(function()
        jumpHeld = true
        task.delay(0.3, function()
            if jumpHeld and not flying and flyMeter > 0 then
                flyStart()
                update()
            end
        end)
    end)

    btn.InputEnded:Connect(function()
        jumpHeld = false
        flyCancel()
        update()
    end)
end

print("[May the gooning goonnence]")

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local function antiStun(char)
    local humanoid = char:WaitForChild("Humanoid")
    RunService.Heartbeat:Connect(function()
        if CollectionService:HasTag(char, "Stunned") then
            CollectionService:RemoveTag(char, "Stunned")
        end
        
        local currentState = humanoid:GetState()
        if currentState == Enum.HumanoidStateType.Physics or 
           currentState == Enum.HumanoidStateType.Ragdoll or 
           currentState == Enum.HumanoidStateType.FallingDown or
           currentState == Enum.HumanoidStateType.PlatformStanding then
            humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        end
    end)
end

if lp.Character then
    antiStun(lp.Character)
end

lp.CharacterAdded:Connect(antiStun)

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")


    RunService.Heartbeat:Connect(disableAnimations)

    
    player.CharacterAdded:Connect(function(newCharacter)
        character = newCharacter
        humanoid = character:WaitForChild("Humanoid")
       
    end)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")
local workspace = Workspace
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
 
local isScriptActive = false
local animationConnections = {}
local meshReplacementConnection = nil
local peeloutPlayed = false
local SPINDASH_ASSET_ID = 95339729195359
local ASSET_ID = 84745056881844
local LMS_ASSET_ID = 140348017868432
local currentNormalModel = nil
local currentLMSModel = nil
local isInLMS = false
local lmsModelConnection = nil
local CUSTOM_BUTTON_ASSET_ID = 9259054284
local PEEL_OUT_VOICE_ID = 137940454798357
local INDICATOR_SOUND_ID = 137940454798357
local lastIndicatorSound = 0
local INDICATOR_VOICE_COOLDOWN = 9.1
local highlightEnabled = false
local highlightCooldown = false
local HIGHLIGHT_COOLDOWN_TIME = 12
local HIGHLIGHT_DURATION = 9
local activeHighlights = {}
local activeBillboards = {}
local ADDITIONAL_ASSET_ID = 73750640215993
local GUI_ID = 96036286115324
local currentSpindashModel = nil
local spindashSpinConnection = nil
local spindashSpeedBoostConnection = nil
local isSpindashActive = false
local spindashSpeedBoost = 1
local spindashTargetSpeed = 1
local SPINDASH_BASELINE = 0.1
local SPINDASH_MAX = 1.5
local SPINDASH_RAMP_TIME = 1
local spindashSpeedRate = (SPINDASH_MAX - SPINDASH_BASELINE) / SPINDASH_RAMP_TIME
local isPeelOutActive = false
local isHoldingPeelOut = false
local isPeelOutReleasing = false
local isDropDashActive = false
local lastImageRectOffset = Vector2.new(0, 0)
local dropDashCheckConnection = nil
local isHoldingInput = false
 
local function onIndicatorAction(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        activateIndicator()
    end
end
 
ContextActionService:BindAction("ActivateIndicator", onIndicatorAction, false, Enum.KeyCode.Y)

 
local function onInputBegan(input, gp)
    if gp then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isHoldingInput = true
        if isPeelOutActive then
            isHoldingPeelOut = true
        end
    end
end
 
local function onInputEnded(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isHoldingInput = false
        isHoldingPeelOut = false
    end
end
 
UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)
 
local function setCharacterSpeedBoost(value)
	if character and character.Parent then
		character:SetAttribute("SpeedBoost", value)
	end
end
 
local function stopSpindashSpeedBoost()
	isSpindashActive = false
	if spindashSpeedBoostConnection then
		spindashSpeedBoostConnection:Disconnect()
		spindashSpeedBoostConnection = nil
	end
	setCharacterSpeedBoost(1)
end
 
local function startSpindashSpeedBoost()
	if spindashSpeedBoostConnection then return end
	isSpindashActive = true
	spindashSpeedBoost = SPINDASH_BASELINE
	spindashTargetSpeed = SPINDASH_BASELINE
	setCharacterSpeedBoost(spindashSpeedBoost)
	spindashSpeedBoostConnection = RunService.Heartbeat:Connect(function(delta)
		if not isSpindashActive then
			if spindashSpeedBoostConnection then
				spindashSpeedBoostConnection:Disconnect()
				spindashSpeedBoostConnection = nil
			end
			return
		end
		if isPeelOutActive then 
			stopSpindashSpeedBoost()
			return 
		end
		local holding = isHoldingInput or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		if holding then
			spindashTargetSpeed = SPINDASH_MAX
		else
			spindashTargetSpeed = SPINDASH_BASELINE
		end
		if spindashSpeedBoost < spindashTargetSpeed then
			spindashSpeedBoost = math.min(spindashSpeedBoost + (spindashSpeedRate * delta), spindashTargetSpeed)
		elseif spindashSpeedBoost > spindashTargetSpeed then
			spindashSpeedBoost = math.max(spindashSpeedBoost - (spindashSpeedRate * delta), spindashTargetSpeed)
		end
		if not isPeelOutActive then
			setCharacterSpeedBoost(spindashSpeedBoost)
		end
	end)
end
 
local function stopSpindashFollow()
	if spindashSpinConnection then
		spindashSpinConnection:Disconnect()
		spindashSpinConnection = nil
	end
	if currentSpindashModel then
		currentSpindashModel:Destroy()
		currentSpindashModel = nil
	end
	local playersFolder = workspace:FindFirstChild("Players")
	if playersFolder then
		local playerFolder = playersFolder:FindFirstChild(player.Name)
		if playerFolder then
			local spindashFolder = playerFolder:FindFirstChild("Spindash")
			if spindashFolder then
				local spindashPart = spindashFolder:FindFirstChild("Spindash")
				if spindashPart then
					spindashPart.Transparency = 0
				end
			end
		end
	end
	stopSpindashSpeedBoost()
end
 
local function stopPeelOutSpeedBoost() end
local function startPeelOutSpeedBoost() end
 
local function freezePlayer()
	setCharacterSpeedBoost(0)
	humanoid.WalkSpeed = 0
end
 
local function unfreezePlayer()
	humanoid.WalkSpeed = 16
end
 
local stopPeelOut = nil
local monitorPeelOutSounds = nil
 
local lastDropDashState = false
 
local function detectDropDash()
	local playerGui = player:WaitForChild("PlayerGui", 5)
	if not playerGui then return end
	local roundGui = playerGui:WaitForChild("Round", 5)
	if not roundGui then return end
	local gameGui = roundGui:WaitForChild("Game", 5)
	if not gameGui then return end
	local abilityGui = gameGui:WaitForChild("Ability", 5)
	if not abilityGui then return end
	local barGui = abilityGui:WaitForChild("Bar", 5)
	if not barGui then return end
	local ab1Gui = barGui:WaitForChild("AB1", 5)
	if not ab1Gui then return end
	local imgGui = ab1Gui:WaitForChild("iMG", 5)
	if not imgGui then return end
 
	dropDashCheckConnection = RunService.Heartbeat:Connect(function()
		if imgGui and imgGui.ImageRectOffset then
			local currentOffset = imgGui.ImageRectOffset
			local isCurrentlyDropDashing = (currentOffset ~= Vector2.new(0, 0))
 
 
			if isCurrentlyDropDashing and not lastDropDashState then
				isDropDashActive = true
				performDropDashLunge()   
			elseif not isCurrentlyDropDashing then
				isDropDashActive = false
			end
 
			lastImageRectOffset = currentOffset
			lastDropDashState = isCurrentlyDropDashing
		end
	end)
end
 
local function replacePlayerFrame()
	local playerGui = player:WaitForChild("PlayerGui", 15)
	if not playerGui then return end
	local roundGui = playerGui:WaitForChild("Round", 15)
	if not roundGui then return end
	local gameGui = roundGui:WaitForChild("Game", 15)
	if not gameGui then return end
	local teamsGui = gameGui:WaitForChild("Teams", 15)
	if not teamsGui then return end
	local playerFrame = nil
	for _ = 1, 60 do
		playerFrame = teamsGui:FindFirstChild(player.Name)
			or teamsGui:FindFirstChild(player.DisplayName)
		if playerFrame then break end
		task.wait(0.25)
	end
	if not playerFrame then return end
	local frame = playerFrame:FindFirstChild("Frame")
	if not frame then return end
	local characterContainer = frame:FindFirstChild("Character")
	if not characterContainer then return end
	characterContainer:ClearAllChildren()
	local iconLabel = Instance.new("ImageLabel")
	iconLabel.Image = "rbxassetid://137740600089778"
	iconLabel.Size = UDim2.new(0.60, 0, 0.60, 0)
	iconLabel.Position = UDim2.new(0.5, 0, 0.38, 0)
	iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	iconLabel.BackgroundTransparency = 1
	iconLabel.ScaleType = Enum.ScaleType.Fit
	iconLabel.Parent = characterContainer
	if characterContainer:IsA("GuiObject") then
		characterContainer.BackgroundTransparency = 1
	end
end
 
local function startSpindashFollow()
	if not currentSpindashModel then return end
	local spindashFolder = currentSpindashModel.Parent
	local spindashPart = spindashFolder and spindashFolder:FindFirstChild("Spindash")
	if not spindashPart then return end
	if spindashSpinConnection then
		spindashSpinConnection:Disconnect()
	end
	spindashSpinConnection = RunService.Heartbeat:Connect(function()
		if not currentSpindashModel or not currentSpindashModel.Parent or not spindashPart or not spindashPart.Parent then
			if spindashSpinConnection then
				spindashSpinConnection:Disconnect()
				spindashSpinConnection = nil
			end
			currentSpindashModel = nil
			stopSpindashFollow()
			return
		end
		local liftOffset = Vector3.new(0, 0, 0)
		if currentSpindashModel:IsA("BasePart") then
			currentSpindashModel.CFrame = spindashPart.CFrame * CFrame.new(liftOffset)
		else
			local primary = currentSpindashModel.PrimaryPart or currentSpindashModel:FindFirstChildWhichIsA("BasePart")
			if primary then
				primary.CFrame = spindashPart.CFrame * CFrame.new(liftOffset)
			end
		end
	end)
end
 
local function replaceSpindashMesh()
	local playersFolder = workspace:FindFirstChild("Players")
	if not playersFolder then return end
	local playerFolder = playersFolder:FindFirstChild(player.Name)
	if not playerFolder then return end
	local spindashFolder = playerFolder:FindFirstChild("Spindash")
	if not spindashFolder then return end
	local spindashPart = spindashFolder:FindFirstChild("Spindash")
	if spindashPart and spindashPart:IsA("BasePart") and not currentSpindashModel then
		local ok, objects = pcall(game.GetObjects, game, "rbxassetid://" .. SPINDASH_ASSET_ID)
		if ok and objects and #objects > 0 then
			local newMesh = objects[1]:Clone()
			local inserted = nil
			if newMesh:IsA("BasePart") then
				inserted = newMesh
				newMesh.Parent = spindashPart.Parent
			else
				newMesh.Parent = spindashPart.Parent
				inserted = newMesh.PrimaryPart or newMesh:FindFirstChildWhichIsA("BasePart")
			end
			if inserted then
				inserted.CFrame = spindashPart.CFrame * CFrame.new(0, 5, 0)
				inserted.Anchored = false
				inserted.CanCollide = false
				currentSpindashModel = newMesh
				spindashPart.Transparency = 1
				startSpindashFollow()
				startSpindashSpeedBoost()
			else
				newMesh:Destroy()
			end
		end
	end
end
 
local function monitorSpindashMesh()
	local function checkAndReplace()
		if isScriptActive then
			replaceSpindashMesh()
		end
	end
	checkAndReplace()
	local playersFolder = workspace:FindFirstChild("Players")
	if playersFolder then
		local playerFolder = playersFolder:FindFirstChild(player.Name)
		if playerFolder then
			local spindashFolder = playerFolder:FindFirstChild("Spindash")
			if spindashFolder then
				spindashFolder.DescendantAdded:Connect(function(descendant)
					if descendant.Name == "Spindash" and descendant:IsA("BasePart") and not currentSpindashModel then
						task.wait(0.1)
						checkAndReplace()
					end
				end)
				spindashFolder.DescendantRemoving:Connect(function(descendant)
					if descendant.Name == "Spindash" and descendant:IsA("BasePart") then
						task.wait(0.1)
						if not (spindashFolder:FindFirstChild("Spindash")) then
							stopSpindashFollow()
						end
					end
				end)
			else
				playerFolder.ChildAdded:Connect(function(child)
					if child.Name == "Spindash" then
						child.DescendantAdded:Connect(function(descendant)
							if descendant.Name == "Spindash" and descendant:IsA("BasePart") and not currentSpindashModel then
								task.wait(0.1)
								checkAndReplace()
							end
						end)
					end
				end)
			end
		else
			playersFolder.ChildAdded:Connect(function(child)
				if child.Name == player.Name then
					child.ChildAdded:Connect(function(spindashChild)
						if spindashChild.Name == "Spindash" then
							spindashChild.DescendantAdded:Connect(function(descendant)
								if descendant.Name == "Spindash" and descendant:IsA("BasePart") and not currentSpindashModel then
									task.wait(0.1)
									checkAndReplace()
								end
							end)
						end
					end)
				end
			end)
		end
	end
	if meshReplacementConnection then
		meshReplacementConnection:Disconnect()
		meshReplacementConnection = nil
	end
	meshReplacementConnection = RunService.Heartbeat:Connect(function()
		if isScriptActive and tick() % 1 < 0.1 then
			checkAndReplace()
		end
	end)
end
 
local function setupSonicViewport()
	local ok, viewportFrame = pcall(function()
		return player.PlayerGui
			:WaitForChild("Round", 30)
			:WaitForChild("Game", 30)
			:WaitForChild("SurvivorHP", 30)
			:WaitForChild("ViewportFrame", 30)
	end)
	if not ok or not viewportFrame then return end
	local viewportModel = viewportFrame
		:WaitForChild("WorldModel", 30)
		:WaitForChild("Default", 30)
	local assetId = "140348017868432"
	local function replaceViewportModel()
		local ok2, objects = pcall(game.GetObjects, game, "rbxassetid://" .. assetId)
		if not ok2 or #objects == 0 then return end
		local newModel = objects[1]:Clone()
		for _, part in ipairs(viewportModel:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Transparency = 1
			end
		end
		newModel.Parent = viewportModel
		local newHumanoid = newModel:FindFirstChildOfClass("Humanoid")
		if newHumanoid then newHumanoid:Destroy() end
		local viewportRootPart = viewportModel:FindFirstChild("HumanoidRootPart")
		if viewportRootPart then
			newModel:PivotTo(viewportRootPart.CFrame * CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), 0))
			local primaryPart = newModel.PrimaryPart or newModel:FindFirstChildWhichIsA("BasePart")
			if primaryPart then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = viewportRootPart
				weld.Part1 = primaryPart
				weld.Parent = viewportRootPart
			end
		end
	end
	replaceViewportModel()
	local viewportHumanoid = viewportModel:FindFirstChild("Humanoid")
	local currentViewportAnimation = nil
	local viewportAnimations = {
		Idle = {id = "rbxassetid://103492267285940", track = nil, shouldLoop = true},
		Walk = {id = "rbxassetid://124016876172487", track = nil, shouldLoop = true},
		Run = {id = "rbxassetid://102091744008058", track = nil, shouldLoop = true},
		Jump = {id = "rbxassetid://125236763187476", track = nil, shouldLoop = false},
		Fall = {id = "rbxassetid://72841784729233", track = nil, shouldLoop = true}
	}
	local function loadViewportAnimation(animName)
		local animData = viewportAnimations[animName]
		if not animData or not viewportHumanoid then return nil end
		local animation = Instance.new("Animation")
		animation.AnimationId = animData.id
		local track = viewportHumanoid:LoadAnimation(animation)
		track.Looped = animData.shouldLoop
		animData.track = track
		return track
	end
	local function playViewportAnimation(animName)
		if not viewportHumanoid then return end
		for _, animData in pairs(viewportAnimations) do
			if animData.track and animData.track.IsPlaying then
				animData.track:Stop()
			end
		end
		local animData = viewportAnimations[animName]
		if animData then
			if not animData.track then loadViewportAnimation(animName) end
			if animData.track then animData.track:Play() end
		end
	end
	local function updateViewportAnimations()
		local newAnimation = "Idle"
		if viewportHumanoid then
			if viewportHumanoid.MoveDirection.Magnitude > 0.1 then
				if viewportHumanoid:GetState() == Enum.HumanoidStateType.Running then
					if viewportHumanoid.WalkSpeed > 16 then
						newAnimation = "Run"
					else
						newAnimation = "Walk"
					end
				end
			else
				local state = viewportHumanoid:GetState()
				if state == Enum.HumanoidStateType.Jumping then
					newAnimation = "Jump"
				elseif state == Enum.HumanoidStateType.Freefall then
					newAnimation = "Fall"
				else
					newAnimation = "Idle"
				end
			end
		end
		if newAnimation ~= currentViewportAnimation then
			playViewportAnimation(newAnimation)
			currentViewportAnimation = newAnimation
		end
	end
	RunService.Heartbeat:Connect(updateViewportAnimations)
	viewportModel.DescendantAdded:Connect(function() task.wait(0.5) replaceViewportModel() end)
end
 
local function loadCustomAsset(url, filename)
	if not isfile(filename) then
		writefile(filename, game:HttpGet(url))
	end
	return getcustomasset(filename)
end
 
local DEFAULT_MUSIC = loadCustomAsset(
	"https://cdn.discordapp.com/attachments/1489017103469248613/1489372093027192832/ALL_THE_SMOKE_Omega_LMS_Outcome_Memories_UST.mp3?ex=69d02d5a&is=69cedbda&hm=1a457972d56b498966e8ce64a643e126e1147abee6ae023464aa252a2c7b3a81&",
	"default.mp3"
)
 
local function setupSonicMusic()
	if not isScriptActive then return end
	local theme = game:GetService("ReplicatedStorage")
		:FindFirstChild("ClientAssets")
		and game.ReplicatedStorage.ClientAssets:FindFirstChild("Sounds")
		and game.ReplicatedStorage.ClientAssets.Sounds:FindFirstChild("mus")
		and game.ReplicatedStorage.ClientAssets.Sounds.mus:FindFirstChild("Game")
		and game.ReplicatedStorage.ClientAssets.Sounds.mus.Game:FindFirstChild("Round")
		and game.ReplicatedStorage.ClientAssets.Sounds.mus.Game.Round:FindFirstChild("SoloTheme")
		and game.ReplicatedStorage.ClientAssets.Sounds.mus.Game.Round.SoloTheme:FindFirstChild("SonicSolo")
	if theme then
		theme.Looped = true
		theme.Volume = 2
		theme.SoundId = DEFAULT_MUSIC
	end
end
local function setupCharacter(char)
	if not isScriptActive then return end
	local originalParts = {}
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then table.insert(originalParts, v) end
	end
	for _, part in ipairs(originalParts) do part.Transparency = 1 end
	local playersFolder = workspace:FindFirstChild("Players")
	local oldVisual = playersFolder and playersFolder:FindFirstChild(player.Name)
	if oldVisual then
		for _, v in ipairs(oldVisual:GetDescendants()) do
			if v:IsA("BasePart") then v.Transparency = 1 end
		end
	end
	local mdl = loadAsset(ASSET_ID)
    if not mdl then return end
 
    currentNormalModel = mdl   
	if oldVisual then mdl.Parent = oldVisual else mdl.Parent = char end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local newHrp = mdl:FindFirstChild("HumanoidRootPart")
	if not hrp or not newHrp then mdl:Destroy() return end
	newHrp.Anchored = true
	newHrp.Transparency = 1
	local existingHum = mdl:FindFirstChildOfClass("Humanoid")
	if existingHum then existingHum:Destroy() end
	local existingAnim = mdl:FindFirstChildOfClass("Animator")
	if existingAnim then existingAnim:Destroy() end
	for _, v in ipairs(mdl:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Transparency = 0
		end
	end
	newHrp.CFrame = hrp.CFrame
	task.wait(0.1)
	newHrp.Transparency = 1
	local syncConn
	syncConn = RunService.Stepped:Connect(function()
		if not char.Parent or not hrp.Parent or not newHrp.Parent then
			if syncConn then syncConn:Disconnect() end
			return
		end
		newHrp.CFrame = hrp.CFrame * CFrame.new(0, 1.1, 0)
	end)
	local animateScript = char:FindFirstChild("Animate")
	if animateScript then animateScript.Disabled = true end
end
 
-- ==================== FIXED BUTTON + INDICATOR ====================
 
local function highlightPlayers(enable)
	if enable then
		for _, hl in ipairs(activeHighlights) do
			if hl and hl.Parent then hl:Destroy() end
		end
		for _, b in ipairs(activeBillboards) do
			if b and b.Parent then b:Destroy() end
		end
		activeHighlights = {}
		activeBillboards = {}
 
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				local hl = Instance.new("Highlight")
				hl.FillColor = Color3.fromRGB(255, 0, 0)
				hl.FillTransparency = 0.7
				hl.OutlineTransparency = 0.5
				hl.OutlineColor = Color3.fromRGB(255, 100, 100)
				hl.Parent = p.Character
 
				table.insert(activeHighlights, hl)
 
 
				local success, billboards = pcall(function()
					return game:GetObjects("rbxassetid://" .. ADDITIONAL_ASSET_ID)
				end)
				if success and #billboards > 0 then
					local billboard = billboards[1]:Clone()
					billboard.Parent = p.Character.HumanoidRootPart
					table.insert(activeBillboards, billboard)
				end
			end
		end
	else
		for _, hl in ipairs(activeHighlights) do
			if hl and hl.Parent then hl:Destroy() end
		end
		for _, b in ipairs(activeBillboards) do
			if b and b.Parent then b:Destroy() end
		end
		activeHighlights = {}
		activeBillboards = {}
	end
end

local function activateIndicator()
	if highlightCooldown then 
		print("Indicator on cooldown!")
		return 
	end
 
	print("âœ… INDICATOR ACTIVATED!") 


    local now = tick()

    if now - lastIndicatorSound > INDICATOR_VOICE_COOLDOWN then
	lastIndicatorSound = now
	playSound(INDICATOR_SOUND_ID, humanoidRootPart, 2)
    end
 
	highlightCooldown = true
	highlightEnabled = true
	highlightPlayers(true)
 
	task.delay(HIGHLIGHT_DURATION, function()
		highlightPlayers(false)
		highlightEnabled = false
	end)
 
	task.delay(HIGHLIGHT_COOLDOWN_TIME, function()
		highlightCooldown = false
	end)
end
 
local function createButton(parent, x, y, color, name, key, callback)
	local btn = Instance.new("ImageButton")
	btn.Name = name
	btn.BackgroundTransparency = 1
	btn.Image = "rbxassetid://72410974345101"
	btn.ImageColor3 = color
 
	if isMobile then
		btn.Size = UDim2.new(0, 55, 0, 55)
		btn.Position = UDim2.new(0, x, 0, y)
	else
		btn.Size = UDim2.new(0, 80, 0, 80)
		btn.Position = UDim2.new(0, x, 0, y)
	end
 
	btn.Parent = parent
 
 
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 0.32, 0)
    nameLbl.Position = UDim2.new(0, 0, 1.05, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = name
	nameLbl.TextColor3 = color
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextScaled = true
	nameLbl.TextStrokeTransparency = 0.8
	nameLbl.Parent = btn
 
 
	local cdLbl = Instance.new("TextLabel")
	cdLbl.Name = "CooldownLabel"
	cdLbl.Size = UDim2.new(1, 0, 1, 0)
	cdLbl.Position = UDim2.new(0, 0, 0, 0)
	cdLbl.BackgroundTransparency = 1
	cdLbl.Text = ""
	cdLbl.TextColor3 = Color3.fromRGB(255, 60, 60)
	cdLbl.Font = Enum.Font.GothamBold
	cdLbl.TextScaled = true
	cdLbl.TextStrokeTransparency = 0.7
	cdLbl.Parent = btn
 
 
	local keyLbl = Instance.new("TextLabel")
	keyLbl.Size = UDim2.new(1, 0, 0.25, 0)
	keyLbl.Position = UDim2.new(0, 5, -0.18, 0)
	keyLbl.BackgroundTransparency = 1
	keyLbl.Text = key
	keyLbl.TextColor3 = color
	keyLbl.Font = Enum.Font.GothamBold
	keyLbl.TextScaled = true
	keyLbl.TextXAlignment = Enum.TextXAlignment.Left
	keyLbl.Parent = btn
 
	btn.Activated:Connect(function()
		if name == "INDICATOR" and highlightCooldown then return end
		if callback then callback() end
	end)
 
	return btn, cdLbl
end
 
local function setupCustomButton()
	if indicatorFrame then indicatorFrame:Destroy() end

	indicatorFrame = Instance.new("Frame")
	indicatorFrame.Name = "IndicatorFrame"
	indicatorFrame.BackgroundTransparency = 1

	if isMobile then
		indicatorFrame.Size = UDim2.new(0,72,0,96)
		indicatorFrame.Position = UDim2.new(0,8,0.5,150-40)
	else
		indicatorFrame.Size = UDim2.new(0,150,0,220)
		indicatorFrame.Position = UDim2.new(1,-20,0.5,220)
	end

	indicatorFrame.Parent = player:WaitForChild("PlayerGui")
		:WaitForChild("Round", 5)
		:WaitForChild("Game", 5)

	local darkRed = Color3.fromRGB(140, 0, 0)

	
	createButton(indicatorFrame, -70, 0, darkRed, "INDICATOR", "Y", activateIndicator)

	
	createButton(indicatorFrame, -160, 0, Color3.fromRGB(140,0,0), "EMOTE", "F", function()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if animator then
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://75751811262833"
				animator:LoadAnimation(anim):Play()
			end
		end
	end)

	
	createButton(indicatorFrame, -250, 0, Color3.fromRGB(140,0,0), "PUNCH", "R", function()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if animator then
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://119975552824132"
				animator:LoadAnimation(anim):Play()
			end
		end
	end)

	
	local hookBtn, hookCdLbl = createButton(indicatorFrame, -340, 0, Color3.fromRGB(0,255,255), "HOOK", "T", activateHook)
	hookCooldownLbl = hookCdLbl  
end

 
local function cleanupCustomButton()
	if customButton then
		customButton:Destroy()
		customButton = nil
	end
end
 
-- ==================== LMS MODEL SWITCHER ====================
local function switchToLMSModel()
	if isInLMS or not character then return end
	isInLMS = true
 
	print("ðŸ”„ Switching to LMS Model...")
 
 
	if currentNormalModel then
		for _, v in ipairs(currentNormalModel:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Transparency = 1
			end
		end
	end
 
 
	if currentLMSModel then 
		currentLMSModel:Destroy() 
		currentLMSModel = nil 
	end
 
	local ok, objects = pcall(game.GetObjects, game, "rbxassetid://" .. LMS_ASSET_ID)
	if not ok or #objects == 0 then
		warn("Failed to load LMS model:", LMS_ASSET_ID)
		return
	end
 
	local lmsModel = objects[1]:Clone()
	lmsModel.Name = "LMS_Model"
 
	local playersFolder = workspace:FindFirstChild("Players")
	local visualFolder = playersFolder and playersFolder:FindFirstChild(player.Name)
 
	if visualFolder then
		lmsModel.Parent = visualFolder
	else
		lmsModel.Parent = character
	end
 
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local newHrp = lmsModel:FindFirstChild("HumanoidRootPart") or lmsModel:FindFirstChildWhichIsA("BasePart")
 
	if hrp and newHrp then
		newHrp.Anchored = true
		newHrp.Transparency = 1
 
		local hum = lmsModel:FindFirstChildOfClass("Humanoid")
		if hum then hum:Destroy() end
		local anim = lmsModel:FindFirstChildOfClass("Animator")
		if anim then anim:Destroy() end
 
		for _, v in ipairs(lmsModel:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
				v.Transparency = 0
			end
		end
 
		task.spawn(function()
			while isInLMS and lmsModel.Parent and hrp.Parent and character.Parent do
				newHrp.CFrame = hrp.CFrame * CFrame.new(0, 1.1, 0)
				task.wait()
			end
		end)
	end
 
	currentLMSModel = lmsModel
	print("âœ… LMS Model Successfully Loaded")
end
 
local function revertToNormalModel()
	isInLMS = false
 
	if currentLMSModel then
		currentLMSModel:Destroy()
		currentLMSModel = nil
	end
 
	if currentNormalModel then
		for _, v in ipairs(currentNormalModel:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Transparency = 0
			end
		end
		print("âœ… Reverted to Normal Model")
	else
		setupCharacter(character)
	end
end
 
 
local function monitorLMS()
	if lmsModelConnection then lmsModelConnection:Disconnect() end
 
	lmsModelConnection = RunService.Heartbeat:Connect(function()
		if not isScriptActive then return end
 
 
		local soloTheme = game:GetService("ReplicatedStorage")
			:FindFirstChild("ClientAssets")
			and game.ReplicatedStorage.ClientAssets:FindFirstChild("Sounds")
			and game.ReplicatedStorage.ClientAssets.Sounds:FindFirstChild("mus")
			and game.ReplicatedStorage.ClientAssets.Sounds.mus:FindFirstChild("Game")
			and game.ReplicatedStorage.ClientAssets.Sounds.mus.Game:FindFirstChild("Round")
			and game.ReplicatedStorage.ClientAssets.Sounds.mus.Game.Round:FindFirstChild("SoloTheme")
			and game.ReplicatedStorage.ClientAssets.Sounds.mus.Game.Round.SoloTheme:FindFirstChild("MetalSonicSolo")
 
		local isSoloPlaying = soloTheme and soloTheme.IsPlaying
 
 
		local aliveCount = 0
		local playersFolder = workspace:FindFirstChild("Players")
		if playersFolder then
			for _, folder in ipairs(playersFolder:GetChildren()) do
				local hum = folder:FindFirstChild("Humanoid")
				if hum and hum.Health > 0 then
					aliveCount += 1
				end
			end
		end
 
		local shouldBeInLMS = isSoloPlaying or (aliveCount <= 1)
 
		if shouldBeInLMS and not isInLMS then
			switchToLMSModel()
		elseif not shouldBeInLMS and isInLMS then
			revertToNormalModel()
		end
	end)
end
 
local function startScript()
	if isScriptActive then return end
	task.wait(3)
	isScriptActive = true
 
	task.spawn(setupSonicViewport)
	setupSonicMusic()
	monitorPeelOutSounds()
	detectDropDash()
	replacePlayerFrame()
 
	if character then
		setupCharacter(character)
	end
 
	setupCustomButton()
	monitorLMS()        
end
 
local function showWaitingNotification()
	local StarterGui = game:GetService("StarterGui")
	StarterGui:SetCore("SendNotification", {
		Title = "mega o-o-omega";
		Text = "made by itsjustyumy caz im sigma skibidi toileto bear";
		Duration = 20;
	})
end
 
local function stopScript()
	if not isScriptActive then return end
	isScriptActive = false
    cleanupCustomButton()
	showWaitingNotification()
	for _, animData in pairs(ANIMATIONS) do
		if animData.track and animData.track.IsPlaying then
			animData.track:Stop()
		end
	end
	stopSpindashFollow()
	if stopPeelOut then stopPeelOut() end
	if dropDashCheckConnection then
		dropDashCheckConnection:Disconnect()
		dropDashCheckConnection = nil
	end
	for _, connection in ipairs(animationConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	animationConnections = {}
	if meshReplacementConnection then
		meshReplacementConnection:Disconnect()
		meshReplacementConnection = nil
	end
	if stopPeelOut then stopPeelOut() end
		task.spawn(function()
		task.wait(10)
		local theme = game:GetService("ReplicatedStorage")
			:FindFirstChild("ClientAssets")
			and game.ReplicatedStorage.ClientAssets:FindFirstChild("Sounds")
			and game.ReplicatedStorage.ClientAssets.Sounds:FindFirstChild("mus")
			and game.ReplicatedStorage.ClientAssets.Sounds.mus:FindFirstChild("Game")
			and game.ReplicatedStorage.ClientAssets.Sounds.mus.Game:FindFirstChild("Round")
			and game.ReplicatedStorage.ClientAssets.Sounds.mus.Game.Round:FindFirstChild("SoloTheme")
			and game.ReplicatedStorage.ClientAssets.Sounds.mus.Game.Round.SoloTheme:FindFirstChild("MetalSonicSolo")
		if theme then
			theme:Stop()
		end
	end)
end
 
local playerModelCache = nil
local isCurrentlySonic = false
 
local function getPlayerModel()
	if not playerModelCache or not playerModelCache.Parent then
		local playersFolder = workspace:FindFirstChild("Players")
		if playersFolder then
			playerModelCache = playersFolder:FindFirstChild(player.Name)
		end
	end
	return playerModelCache
end
 
local function isSonic()
	local model = getPlayerModel()
	return model and model:GetAttribute("Character") == "MetalSonic"
end
 
local function onHeartbeat()
	local sonicCheck = isSonic()
	if sonicCheck ~= isCurrentlySonic then
		isCurrentlySonic = sonicCheck
		if isCurrentlySonic then
			startScript()
		else
			stopScript()
		end
	end
end
 
local function checkCharacterAttribute() end
 
local function monitorCharacterAttribute() end
 
local currentAnimation = nil
local animationsToDisable = {
	"rbxassetid://106608035337434343447",
	"rbxassetid://9191426583290243434",
	"rbxassetid://1381145986434514343434",
	"rbxassetid://12355823787878779758443434",
	"rbxassetid://12830070429117134343434",
	"rbxassetid://8308909881303234343434",
	"rbxassetid://1246987295976683434343343",
	"rbxassetid://7622317178271243434343434"
}
local jumpStartTime = 0
local jumpAnimationDuration = 0.6
local runStartTime = 0
local isRunning = false
local speedBoostRate = (4 - 1) / 1.25
local lastWalkSpeed = 16
local speedChangeThreshold = 2
local isSpeedBoostActive = false
local lastSpeedCheckTime = 0
local speedCheckInterval = 0.1
 
local function loadAnimation(animName)
	local animData = ANIMATIONS[animName]
	if not animData then return nil end
	local animation = Instance.new("Animation")
	animation.AnimationId = animData.id
	local track = humanoid:LoadAnimation(animation)
	track.Looped = animData.shouldLoop
	animData.track = track
	return track
end
 
local function playAnimation(animName)
	for _, animData in pairs(ANIMATIONS) do
		if animData.track and animData.track.IsPlaying then
			animData.track:Stop()
		end
	end
	local animData = ANIMATIONS[animName]
	if animData then
		if not animData.track then loadAnimation(animName) end
		if animData.track then
			animData.track:Play()
			if animName == "SuperRun" then
				animData.track:AdjustSpeed(3.8)
			end
		end
	end
end
 
local function updateAnimations()
	if not isScriptActive then return end
		if isPeelOutActive then
		character:SetAttribute("SpeedBoost", 1.1)
		isSpeedBoostActive = false
		isRunning = false
		stopSpindashSpeedBoost()
		return
	end
		if isSpindashActive then
		return
	end
	if not isSpindashActive and not isPeelOutActive and not isPeelOutReleasing then
		local currentTime = tick()
		if currentTime - lastSpeedCheckTime >= speedCheckInterval then
			lastSpeedCheckTime = currentTime
			local currentWalkSpeed = humanoid.WalkSpeed
			local speedChange = currentWalkSpeed - lastWalkSpeed
			if speedChange > speedChangeThreshold and currentWalkSpeed > 16 and humanoid.MoveDirection.Magnitude > 0.1 then
				if not isRunning then
					isRunning = true
					runStartTime = tick()
				end
				isSpeedBoostActive = true
			elseif speedChange < -speedChangeThreshold or (currentWalkSpeed <= 16 and isSpeedBoostActive) then
				if isRunning then
					isRunning = false
				end
				isSpeedBoostActive = false
				character:SetAttribute("SpeedBoost", 1)
			end
			lastWalkSpeed = currentWalkSpeed
		end
	end
	local state = humanoid:GetState()
	local newAnimation = nil
	if state == Enum.HumanoidStateType.Jumping then
		if currentAnimation ~= "Jump" then jumpStartTime = tick() end
		newAnimation = "Jump"
	elseif state == Enum.HumanoidStateType.Freefall then
		if tick() - jumpStartTime > jumpAnimationDuration then
			newAnimation = "Fall"
		else
			newAnimation = "Jump"
		end
	elseif humanoid.MoveDirection.Magnitude > 0.1 then
		if humanoid.WalkSpeed > 16 then
			newAnimation = "Run"
		else
			newAnimation = "Walk"
		end
	else
		newAnimation = "Idle"
	end
	if not isPeelOutActive and not isSpindashActive then
		local currentSpeedBoost = character:GetAttribute("SpeedBoost") or 1
		if currentSpeedBoost >= 2.5 and isSpeedBoostActive and humanoid.MoveDirection.Magnitude > 0.1 and humanoid.WalkSpeed > 16 and state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
			newAnimation = "SuperRun"
		end
		if isSpeedBoostActive and isRunning then
			local runDuration = tick() - runStartTime
			local newSpeedBoost = math.min(1 + (runDuration * speedBoostRate), 3)
			local currentBoost = character:GetAttribute("SpeedBoost")
			if currentBoost ~= nil then
				character:SetAttribute("SpeedBoost", newSpeedBoost)
			end
		end
	end
	if newAnimation and newAnimation ~= currentAnimation then
		playAnimation(newAnimation)
		currentAnimation = newAnimation
	end
end
 
local function disableAnimations()
	if not isScriptActive then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
		for _, animId in ipairs(animationsToDisable) do
			if track.Animation and track.Animation.AnimationId == animId then
				track:Stop()
				break
			end
		end
	end
end
 
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
	playerModelCache = nil
	monitorSpindashMesh()
	setupCharacter(newChar)
	for name in pairs(ANIMATIONS) do
		if ANIMATIONS[name].track then
			ANIMATIONS[name].track:Stop()
			ANIMATIONS[name].track = nil
		end
	end
	for name in pairs(ANIMATIONS) do loadAnimation(name) end
	playAnimation("Idle")
	table.insert(animationConnections, humanoid.StateChanged:Connect(updateAnimations))
	table.insert(animationConnections, RunService.Heartbeat:Connect(updateAnimations))
	table.insert(animationConnections, RunService.Heartbeat:Connect(disableAnimations))
end)
 
if monitorSpindashMesh then monitorSpindashMesh() end
if setupCharacter and character and isScriptActive then
	setupCharacter(character)
end
 
if isScriptActive then
	for name in pairs(ANIMATIONS) do
		loadAnimation(name)
	end
	playAnimation("Idle")
	if humanoid then
		table.insert(animationConnections, humanoid.StateChanged:Connect(updateAnimations))
		table.insert(animationConnections, RunService.Heartbeat:Connect(updateAnimations))
		table.insert(animationConnections, RunService.Heartbeat:Connect(disableAnimations))
	end
end
 
task.spawn(function()
	while true do
		local playersFolder = workspace:FindFirstChild("Players")
		if playersFolder then
			local playerFolder = playersFolder:FindFirstChild(player.Name)
			if playerFolder then
				local defaultFolder = playerFolder:FindFirstChild("Default")
				if defaultFolder then
					local waist = defaultFolder:FindFirstChild("Waist")
					local hrpDefault = defaultFolder:FindFirstChild("HumanoidRootPart")
					if waist and waist:IsA("BasePart") then waist.Transparency = 1 end
					if hrpDefault and hrpDefault:IsA("BasePart") then hrpDefault.Transparency = 1 end
				end
			end
		end
		task.wait(0.1)
	end
end)
 
stopPeelOut = function()
	isPeelOutActive = false
	peeloutPlayed = false       
	isHoldingPeelOut = false
	isPeelOutReleasing = true
	unfreezePlayer()
	stopPeelOutSpeedBoost()
	isRunning = false
	isSpeedBoostActive = false
	runStartTime = tick()
	character:SetAttribute("SpeedBoost", 1.1)
	if ANIMATIONS.PeelCharge.track and ANIMATIONS.PeelCharge.track.IsPlaying then
		ANIMATIONS.PeelCharge.track:Stop()
	end
 
	task.spawn(function()
		task.wait(0.5)
		isPeelOutReleasing = false
	end)
end
 
monitorPeelOutSounds = function()
	if not humanoidRootPart then return end
 
	local lastPeelStart = 0
	local VOICE_COOLDOWN = 8.9 
 
	local function checkForSounds()
		if not isScriptActive or not humanoidRootPart.Parent then return end
 
		local peelCharge = humanoidRootPart:FindFirstChild("DashStart") 
            or humanoidRootPart:FindFirstChild("DestructiveCharge")
 
		if peelCharge and peelCharge:IsA("Sound") and not isPeelOutActive then
			local now = tick()
 
			isPeelOutActive = true
			freezePlayer()
			playAnimation("Charge")
			currentAnimation = "Charge"
 
 
			if now - lastPeelStart > VOICE_COOLDOWN then
				lastPeelStart = now
				playSound(PEEL_OUT_VOICE_ID, humanoidRootPart, 2.0)
				print("ðŸ”Š Peel Out voice played once")
			end
 
			if startPeelOutSpeedBoost then
				startPeelOutSpeedBoost()
			end
		end
 
 
		local peelRelease = humanoidRootPart:FindFirstChild("DashEnd") 
             or humanoidRootPart:FindFirstChild("DestructiveRelease")

             if peelRelease and peelRelease:IsA("Sound") then
 
			if isPeelOutActive then
				stopPeelOut()
			end
		end
	end
 
 
	humanoidRootPart.ChildAdded:Connect(function(child)
	if child.Name == "DashStart" 
        or child.Name == "DashEnd" 
        or child.Name == "DestructiveCharge" 
        or child.Name == "DestructiveRelease" then
			task.delay(0.08, checkForSounds)
		end
	end)
 
	humanoidRootPart.ChildRemoved:Connect(function(child)
			if child.Name == "DashStart" 
        or child.Name == "DashEnd" 
        or child.Name == "DestructiveCharge" 
        or child.Name == "DestructiveRelease" then
			task.delay(0.08, checkForSounds)
		end
	end)
 
 
	RunService.Heartbeat:Connect(function()
		if tick() % 0.5 < 0.06 then
			checkForSounds()
		end
	end)
 
	checkForSounds()
	print("âœ… PeelOut monitor fixed - voice should play only once now")
end
 
local initialSonic = isSonic()
if initialSonic then
	startScript()
else
	showWaitingNotification()
end
isCurrentlySonic = initialSonic
 
RunService.Heartbeat:Connect(onHeartbeat)
 
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		if highlightEnabled then
			task.wait(0.5)
			highlightPlayers(true)
		end
	end)
end)

-- ====================== KEYBINDS FOR ALL ABILITY BUTTONS (PC) ======================
task.wait(2) 

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	
	if input.KeyCode == Enum.KeyCode.F then
		if animator then
			local anim = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://75751811262833"
			local track = animator:LoadAnimation(anim)
			track:Play()
		end
		
	elseif input.KeyCode == Enum.KeyCode.R then
		if animator then
			local anim = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://119975552824132"
			local track = animator:LoadAnimation(anim)
			track:Play()
		end
		
	elseif input.KeyCode == Enum.KeyCode.T then
		if activateHook then activateHook() end
		
	elseif input.KeyCode == Enum.KeyCode.Y then
		if activateIndicator then activateIndicator() end
	end
end)
