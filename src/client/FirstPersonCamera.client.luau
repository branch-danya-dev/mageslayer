-- Deliberately retains Roblox's native camera controls: no Scriptable camera.
-- A very small post-camera offset adds speed/landing feedback without input lag.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("MovementConfig"))
local MovementMath = require(ReplicatedStorage:WaitForChild("MovementMath"))

local humanoid = nil
local root = nil
local bobClock = 0
local bobWeight = 0
local landingStrength = 0
local lastGrounded = true
local worstFallSpeed = 0

local function attachCharacter(character)
    local nextHumanoid = character:WaitForChild("Humanoid")
    local nextRoot = character:WaitForChild("HumanoidRootPart")
    if player.Character ~= character then
        return
    end

    humanoid, root = nextHumanoid, nextRoot
    bobClock, bobWeight, landingStrength = 0, 0, 0
    lastGrounded = nextHumanoid.FloorMaterial ~= Enum.Material.Air
    worstFallSpeed = 0
    player.CameraMode = Enum.CameraMode.LockFirstPerson
end

player.CharacterRemoving:Connect(function(character)
    if humanoid and humanoid.Parent == character then
        humanoid, root = nil, nil
    end
end)
player.CharacterAdded:Connect(attachCharacter)
if player.Character then
    task.defer(attachCharacter, player.Character)
end
player.CameraMode = Enum.CameraMode.LockFirstPerson

RunService:BindToRenderStep("MageSlayerFirstPersonCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local charge = if humanoid then (humanoid:GetAttribute("MageSlayerRunCharge") or 0) else 0
    local moving = humanoid ~= nil and humanoid.Health > 0 and humanoid.MoveDirection.Magnitude > 0.05
    local grounded = humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air

    local targetFov = Config.FirstPersonFov
    if moving then
        targetFov += Config.MaxSpeedFovBonus * charge
    end
    camera.FieldOfView += (targetFov - camera.FieldOfView)
        * MovementMath.smoothingAlpha(Config.FovResponse, dt)

    if not humanoid or not root or humanoid.Health <= 0 then
        return
    end

    if not grounded then
        worstFallSpeed = math.min(worstFallSpeed, root.AssemblyLinearVelocity.Y)
    elseif not lastGrounded then
        landingStrength = math.clamp((-worstFallSpeed - 10) / 55, 0, 1)
        worstFallSpeed = 0
    end
    lastGrounded = grounded

    landingStrength *= math.exp(-Config.LandingRecovery * dt)
    local bobTarget = if Config.EnableHeadBob and moving and grounded then 1 else 0
    bobWeight += (bobTarget - bobWeight) * MovementMath.smoothingAlpha(12, dt)

    if bobWeight > 0.001 then
        bobClock += math.min(dt, 0.05) * Config.HeadBobFrequency
    end

    local amplitude = Config.HeadBobAmplitude * bobWeight
    local xBob = math.sin(bobClock) * amplitude
    local yBob = math.abs(math.cos(bobClock)) * amplitude - landingStrength * Config.LandingDip
    local pitch = math.rad(landingStrength * Config.LandingPitchDegrees)

    -- Native CoreCamera rewrites its own CFrame next frame: no accumulated drift.
    camera.CFrame = camera.CFrame * CFrame.new(xBob, yBob, 0) * CFrame.Angles(pitch, 0, 0)
end)
