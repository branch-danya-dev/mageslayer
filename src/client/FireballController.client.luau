-- Temporary auto-equipped LEFT-hand fireball: LMB tap/hold, no tool or hand animation.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("FireballConfig"))
local FireballMath = require(ReplicatedStorage:WaitForChild("FireballMath"))
local Visuals = require(script.Parent:WaitForChild("FireballVisuals"))

local remotes = ReplicatedStorage:WaitForChild("SpellRemotes")
local castRequest = remotes:WaitForChild("CastFireball")
local visualEvent = remotes:WaitForChild("FireballVisuals")

local firing = false
local lastLocalCastAt = -math.huge
local nextShotId = 0

-- A small, unobtrusive reticle is necessary when the first-person cursor is hidden.
local screen = Instance.new("ScreenGui")
screen.Name = "MageSlayerFireballReticle"
screen.IgnoreGuiInset = true
screen.ResetOnSpawn = false
screen.DisplayOrder = 10
screen.Parent = player:WaitForChild("PlayerGui")

local reticle = Instance.new("Frame")
reticle.Name = "CenterDot"
reticle.AnchorPoint = Vector2.new(0.5, 0.5)
reticle.Position = UDim2.fromScale(0.5, 0.5)
reticle.Size = UDim2.fromOffset(4, 4)
reticle.BorderSizePixel = 0
reticle.BackgroundColor3 = Config.ReticleColor
reticle.Parent = screen

local roundness = Instance.new("UICorner")
roundness.CornerRadius = UDim.new(1, 0)
roundness.Parent = reticle

local function pulseReticle()
    TweenService:Create(
        reticle, TweenInfo.new(0.07),
        { Size = UDim2.fromOffset(8, 8), BackgroundTransparency = 0.18 }
    ):Play()
    task.delay(0.08, function()
        if reticle.Parent then
            TweenService:Create(
                reticle, TweenInfo.new(0.16),
                { Size = UDim2.fromOffset(4, 4), BackgroundTransparency = 0 }
            ):Play()
        end
    end)
end

local function castOnce()
    local now = os.clock()
    if not FireballMath.canCast(now, lastLocalCastAt, Config.CastInterval) then
        return
    end

    local character = player.Character
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
    local camera = workspace.CurrentCamera
    if not humanoid or not root or not camera or humanoid.Health <= 0 then
        return
    end
    if UserInputService:GetFocusedTextBox() then
        return
    end

    local viewCenter = camera.ViewportSize * 0.5
    local aimRay = camera:ViewportPointToRay(viewCenter.X, viewCenter.Y)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { character, Visuals.getFolder() }
    rayParams.IgnoreWater = true
    local aimHit = workspace:Raycast(aimRay.Origin, aimRay.Direction * Config.MaxDistance, rayParams)
    local targetPosition = if aimHit then aimHit.Position
        else aimRay.Origin + aimRay.Direction * Config.MaxDistance

    local origin = root.CFrame:PointToWorldSpace(Config.SpawnOffset)
    local delta = targetPosition - origin
    if delta.Magnitude < 1 then
        return
    end

    lastLocalCastAt = now
    nextShotId += 1
    if nextShotId > 1000000000 then
        nextShotId = 1
    end

    -- Prediction: the player sees and hears the shot BEFORE the server response.
    Visuals.spawn(player.UserId, nextShotId, origin, delta.Unit)
    Visuals.localMuzzle(camera)
    pulseReticle()

    -- Only the server is allowed to decide cast legitimacy, hit and damage.
    castRequest:FireServer(Config.AllowedHand, Config.Id, nextShotId, targetPosition)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        firing = true
        castOnce()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        firing = false
    end
end)

UserInputService.WindowFocusReleased:Connect(function()
    firing = false
end)

player.CharacterRemoving:Connect(function()
    firing = false
end)

RunService.Heartbeat:Connect(function()
    if firing then
        castOnce()
    end
end)

visualEvent.OnClientEvent:Connect(function(eventType, ownerUserId, shotId, a, b)
    if eventType == "spawn" then
        Visuals.spawn(ownerUserId, shotId, a, b)
    elseif eventType == "impact" then
        Visuals.impact(ownerUserId, shotId, a, b)
    elseif eventType == "expire" then
        Visuals.expire(ownerUserId, shotId)
    end
end)
