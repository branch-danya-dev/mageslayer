-- Server owns fireball authorization, collision and damage. Clients own only visuals.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("FireballConfig"))
local FireballMath = require(ReplicatedStorage:WaitForChild("FireballMath"))

local remotes = ReplicatedStorage:FindFirstChild("SpellRemotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "SpellRemotes"
    remotes.Parent = ReplicatedStorage
end

local castRequest = remotes:FindFirstChild("CastFireball")
if not castRequest then
    castRequest = Instance.new("RemoteEvent")
    castRequest.Name = "CastFireball"
    castRequest.Parent = remotes
end

local visuals = remotes:FindFirstChild("FireballVisuals")
if not visuals then
    visuals = Instance.new("RemoteEvent")
    visuals.Name = "FireballVisuals"
    visuals.Parent = remotes
end

local lastCastByPlayer = {}
local active = {}

local function isFiniteVector(value)
    if typeof(value) ~= "Vector3" then
        return false
    end
    for _, coordinate in { value.X, value.Y, value.Z } do
        if coordinate ~= coordinate or math.abs(coordinate) > 1000000 then
            return false
        end
    end
    return true
end

local function getLivingCharacter(player)
    local character = player.Character
    if not character then
        return nil, nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not root:IsA("BasePart") or humanoid.Health <= 0 then
        return nil, nil
    end
    return character, root
end

local function tryCast(player, hand, spellId, shotId, targetPosition)
    if hand ~= Config.AllowedHand or spellId ~= Config.Id then
        return
    end
    if not FireballMath.isValidShotId(shotId) or not isFiniteVector(targetPosition) then
        return
    end

    local character, root = getLivingCharacter(player)
    if not character then
        return
    end

    local now = os.clock()
    local minInterval = Config.CastInterval - Config.ServerIntervalTolerance
    if not FireballMath.canCast(now, lastCastByPlayer[player] or -math.huge, minInterval) then
        return
    end

    -- Camera target is only a hint. The server computes the real muzzle and direction.
    local origin = root.CFrame:PointToWorldSpace(Config.SpawnOffset)
    local toTarget = targetPosition - origin
    if toTarget.Magnitude < 1 or (targetPosition - root.Position).Magnitude > Config.MaxDistance + 28 then
        return
    end

    local horizontalAim = Vector3.new(toTarget.X, 0, toTarget.Z)
    local horizontalForward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    if horizontalAim.Magnitude > 1 and horizontalForward.Magnitude > 0.1
        and horizontalAim.Unit:Dot(horizontalForward.Unit) < -0.2 then
        return
    end

    local direction = toTarget.Unit
    lastCastByPlayer[player] = now

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character }
    params.IgnoreWater = true

    table.insert(active, {
        ownerUserId = player.UserId,
        shotId = shotId,
        character = character,
        position = origin,
        direction = direction,
        distance = 0,
        params = params
    })
    visuals:FireAllClients("spawn", player.UserId, shotId, origin, direction)
end

castRequest.OnServerEvent:Connect(tryCast)

Players.PlayerRemoving:Connect(function(player)
    lastCastByPlayer[player] = nil
end)

local function applyHitDamage(hitPart, ownerCharacter)
    local model = hitPart:FindFirstAncestorOfClass("Model")
    if not model or model == ownerCharacter then
        return
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        humanoid:TakeDamage(Config.BaseDamage)
    end
end

RunService.Heartbeat:Connect(function(dt)
    if #active == 0 then
        return
    end

    for index = #active, 1, -1 do
        local shot = active[index]
        local nextDistance = FireballMath.advanceDistance(
            shot.distance, math.min(dt, 0.12), Config.ProjectileSpeed, Config.MaxDistance
        )
        local travel = nextDistance - shot.distance
        local result = if travel > 0 then Workspace:Spherecast(
            shot.position, Config.ProjectileRadius, shot.direction * travel, shot.params
        ) else nil

        if result then
            applyHitDamage(result.Instance, shot.character)
            visuals:FireAllClients("impact", shot.ownerUserId, shot.shotId, result.Position, result.Normal)
            table.remove(active, index)
        elseif nextDistance >= Config.MaxDistance then
            visuals:FireAllClients("expire", shot.ownerUserId, shot.shotId)
            table.remove(active, index)
        else
            shot.position += shot.direction * travel
            shot.distance = nextDistance
        end
    end
end)
