-- Client-only responsive fireball visuals. Does not determine damage or hits.
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("FireballConfig"))
local Visuals = {}
local projectiles = {}

local folder = Instance.new("Folder")
folder.Name = "MageSlayerClientFireballVFX"
folder.Parent = workspace

local function key(ownerUserId, shotId)
    return tostring(ownerUserId) .. ":" .. tostring(shotId)
end

local function createCore(origin, direction)
    local ball = Instance.new("Part")
    ball.Name = "Fireball"
    ball.Shape = Enum.PartType.Ball
    ball.Material = Enum.Material.Neon
    ball.Size = Vector3.new(1.12, 1.12, 1.12)
    ball.Color = Config.ProjectileCoreColor
    ball.Transparency = 0.07
    ball.CastShadow = false
    ball.Anchored = true
    ball.CanCollide = false
    ball.CanTouch = false
    ball.CanQuery = false
    ball.CFrame = CFrame.lookAt(origin, origin + direction)
    ball.Parent = folder

    local top = Instance.new("Attachment")
    top.Position = Vector3.new(0, 0.38, 0)
    top.Parent = ball

    local bottom = Instance.new("Attachment")
    bottom.Position = Vector3.new(0, -0.38, 0)
    bottom.Parent = ball

    local trail = Instance.new("Trail")
    trail.Attachment0 = top
    trail.Attachment1 = bottom
    trail.Lifetime = 0.17
    trail.MinLength = 0.05
    trail.FaceCamera = true
    trail.LightEmission = 1
    trail.Color = ColorSequence.new(Config.ProjectileCoreColor, Config.ProjectileOuterColor)
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.10),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    trail.Parent = ball

    local sparks = Instance.new("ParticleEmitter")
    sparks.Name = "Embers"
    sparks.Texture = Config.FlameTextureId
    sparks.Color = ColorSequence.new(Config.ProjectileCoreColor, Config.ProjectileOuterColor)
    sparks.LightEmission = 1
    sparks.Rate = 28
    sparks.Lifetime = NumberRange.new(0.1, 0.2)
    sparks.Speed = NumberRange.new(0.4, 1.3)
    sparks.SpreadAngle = Vector2.new(160, 160)
    sparks.Rotation = NumberRange.new(0, 360)
    sparks.RotSpeed = NumberRange.new(-160, 160)
    sparks.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.34),
        NumberSequenceKeypoint.new(1, 0)
    })
    sparks.Parent = ball

    local light = Instance.new("PointLight")
    light.Color = Config.ProjectileCoreColor
    light.Brightness = 1.35
    light.Range = 9
    light.Parent = ball

    return ball
end

local function stopProjectile(ownerUserId, shotId)
    local id = key(ownerUserId, shotId)
    local shot = projectiles[id]
    if not shot then
        return
    end
    projectiles[id] = nil

    for _, child in shot.part:GetChildren() do
        if child:IsA("Trail") or child:IsA("ParticleEmitter") then
            child.Enabled = false
        elseif child:IsA("PointLight") then
            child.Enabled = false
        end
    end
    shot.part.Transparency = 1
    Debris:AddItem(shot.part, 0.22)
end

function Visuals.getFolder()
    return folder
end

function Visuals.spawn(ownerUserId, shotId, origin, direction)
    local id = key(ownerUserId, shotId)
    if projectiles[id] then
        return -- shooter predicted this shot before the server echoed it
    end
    if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" or direction.Magnitude < 0.1 then
        return
    end

    local unit = direction.Unit
    projectiles[id] = {
        part = createCore(origin, unit),
        position = origin,
        direction = unit,
        distance = 0,
        ownerUserId = ownerUserId,
        shotId = shotId
    }
end

function Visuals.localMuzzle(camera)
    local flash = Instance.new("Part")
    flash.Name = "LeftHandCastFlash"
    flash.Shape = Enum.PartType.Ball
    flash.Material = Enum.Material.Neon
    flash.Color = Config.ProjectileCoreColor
    flash.Size = Vector3.new(0.35, 0.35, 0.35)
    flash.Transparency = 0.12
    flash.Anchored = true
    flash.CanCollide = false
    flash.CanQuery = false
    flash.CanTouch = false
    flash.CastShadow = false
    flash.CFrame = camera.CFrame * CFrame.new(-0.75, -0.45, -1.65)
    flash.Parent = folder

    TweenService:Create(
        flash, TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(1.25, 1.25, 1.25), Transparency = 1 }
    ):Play()
    Debris:AddItem(flash, 0.16)

    if Config.CastSoundId ~= "" then
        local sound = Instance.new("Sound")
        sound.Name = "FireballCast"
        sound.SoundId = Config.CastSoundId
        sound.Volume = Config.CastSoundVolume
        sound.PlaybackSpeed = Config.CastSoundPlaybackSpeed
        sound.Parent = SoundService
        sound:Play()
        Debris:AddItem(sound, 2)
    end
end

function Visuals.impact(ownerUserId, shotId, position, normal)
    stopProjectile(ownerUserId, shotId)
    if typeof(position) ~= "Vector3" then
        return
    end

    local flash = Instance.new("Part")
    flash.Name = "FireballImpactFlash"
    flash.Shape = Enum.PartType.Ball
    flash.Material = Enum.Material.Neon
    flash.Color = Config.ProjectileCoreColor
    flash.Size = Vector3.new(0.4, 0.4, 0.4)
    flash.Transparency = 0.12
    flash.Anchored = true
    flash.CanCollide = false
    flash.CanQuery = false
    flash.CanTouch = false
    flash.CastShadow = false
    flash.Position = if typeof(normal) == "Vector3" then position + normal * 0.15 else position
    flash.Parent = folder

    local sparks = Instance.new("ParticleEmitter")
    sparks.Name = "ImpactSparks"
    sparks.Texture = Config.FlameTextureId
    sparks.Color = ColorSequence.new(Config.ProjectileCoreColor, Config.ProjectileOuterColor)
    sparks.LightEmission = 1
    sparks.Rate = 0
    sparks.Lifetime = NumberRange.new(0.16, 0.30)
    sparks.Speed = NumberRange.new(8, 17)
    sparks.Drag = 3
    sparks.SpreadAngle = Vector2.new(180, 180)
    sparks.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.48),
        NumberSequenceKeypoint.new(1, 0)
    })
    sparks.Parent = flash
    sparks:Emit(19)

    local light = Instance.new("PointLight")
    light.Color = Config.ProjectileCoreColor
    light.Brightness = 2.3
    light.Range = 10
    light.Parent = flash

    TweenService:Create(
        flash, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(3, 3, 3), Transparency = 1 }
    ):Play()
    TweenService:Create(light, TweenInfo.new(0.16), { Brightness = 0 }):Play()
    Debris:AddItem(flash, 0.42)
end

function Visuals.expire(ownerUserId, shotId)
    stopProjectile(ownerUserId, shotId)
end

RunService.RenderStepped:Connect(function(dt)
    local step = math.min(math.max(dt, 0), 0.06) * Config.ProjectileSpeed
    for id, shot in pairs(projectiles) do
        local travel = math.min(step, Config.MaxDistance - shot.distance)
        shot.position += shot.direction * travel
        shot.distance += travel
        shot.part.CFrame = CFrame.lookAt(shot.position, shot.position + shot.direction)
        if shot.distance >= Config.MaxDistance then
            stopProjectile(shot.ownerUserId, shot.shotId)
        end
    end
end)

return Visuals
