-- Native Roblox first-person aiming with restrained speed and jump feedback.
-- Roblox does not expose a true fisheye lens here; widening FOV is the safe approximation.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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
local lastJumpStamp = 0
local jumpKick = 0
local strafeRoll = 0

local function attachCharacter(character)
    local nextHumanoid = character:WaitForChild("Humanoid")
    local nextRoot = character:WaitForChild("HumanoidRootPart")
    if player.Character ~= character then
        return
    end

    humanoid, root = nextHumanoid, nextRoot
    bobClock, bobWeight, landingStrength = 0, 0, 0
    jumpKick, strafeRoll = 0, 0
    lastJumpStamp = 0
    lastGrounded = nextHumanoid.FloorMaterial ~= Enum.Material.Air
    worstFallSpeed = 0
    player.CameraMode = Enum.CameraMode.LockFirstPerson
    UserInputService.MouseIconEnabled = false
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
UserInputService.MouseIconEnabled = false

RunService:BindToRenderStep("MageSlayerFirstPersonCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local alive = humanoid ~= nil and humanoid.Health > 0 and root ~= nil
    local moving = alive and humanoid.MoveDirection.Magnitude > 0.05
    local grounded = alive and humanoid.FloorMaterial ~= Enum.Material.Air

    local speedRatio = 0
    if alive then
        local velocity = root.AssemblyLinearVelocity
        local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
        local maxSpeed = Config.MaxRunSpeed + Config.HopBonusCap
        speedRatio = math.clamp(
            (horizontalSpeed - Config.BaseRunSpeed) / (maxSpeed - Config.BaseRunSpeed), 0, 1
        )

        local stamp = humanoid:GetAttribute("MageSlayerJumpPulse") or 0
        if stamp ~= lastJumpStamp then
            lastJumpStamp = stamp
            jumpKick = 1
        end
    end
    jumpKick *= math.exp(-Config.JumpFovRecovery * dt)

    local targetFov = Config.FirstPersonFov
        + Config.MaxSpeedFovBonus * speedRatio
        + Config.JumpFovPulse * jumpKick
    camera.FieldOfView += (targetFov - camera.FieldOfView)
        * MovementMath.smoothingAlpha(Config.FovResponse, dt)

    if not alive then
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
        bobClock += math.min(dt, 0.05) * Config.HeadBobFrequency * (1 + 0.25 * speedRatio)
    end

    local amplitude = Config.HeadBobAmplitude * (1 + 0.35 * speedRatio) * bobWeight
    local xBob = math.sin(bobClock) * amplitude
    local yBob = math.abs(math.cos(bobClock)) * amplitude
        - landingStrength * Config.LandingDip + jumpKick * 0.012

    local strafe = if moving then humanoid.MoveDirection:Dot(camera.CFrame.RightVector) else 0
    local targetRoll = -strafe * Config.StrafeLeanDegrees * speedRatio
    strafeRoll += (targetRoll - strafeRoll) * MovementMath.smoothingAlpha(10, dt)

    camera.CFrame = camera.CFrame
        * CFrame.new(xBob, yBob, 0)
        * CFrame.Angles(math.rad(landingStrength * Config.LandingPitchDegrees), 0, math.rad(strafeRoll))
end)
