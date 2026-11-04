-- Humanoid remains responsible for collisions and movement on all input devices.
-- The controller adds run charge and a forgiving SINGLE jump, not custom flight.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("MovementConfig"))
local MovementMath = require(ReplicatedStorage:WaitForChild("MovementMath"))

local session = nil
local stateChangedConnection = nil

local function detachCharacter()
    if stateChangedConnection then
        stateChangedConnection:Disconnect()
        stateChangedConnection = nil
    end
    session = nil
end

local function attachCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")
    if player.Character ~= character then
        return
    end

    detachCharacter()
    humanoid.UseJumpPower = false
    humanoid.JumpHeight = Config.JumpHeight
    humanoid.WalkSpeed = Config.BaseRunSpeed

    local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
    session = {
        humanoid = humanoid,
        root = root,
        charge = 0,
        lastDirection = Vector3.zero,
        wasGrounded = grounded,
        lastGroundedAt = if grounded then os.clock() else -math.huge,
        consumedJump = false,
        bufferedJumpUntil = -math.huge,
        lastJumpRequestAt = -math.huge
    }
    humanoid:SetAttribute("MageSlayerRunCharge", 0)

    stateChangedConnection = humanoid.StateChanged:Connect(function(_, newState)
        if session and session.humanoid == humanoid and newState == Enum.HumanoidStateType.Jumping then
            session.consumedJump = true
        end
    end)
end

player.CharacterRemoving:Connect(function(character)
    if session and session.humanoid.Parent == character then
        detachCharacter()
    end
end)
player.CharacterAdded:Connect(attachCharacter)
if player.Character then
    task.defer(attachCharacter, player.Character)
end

-- JumpRequest is emitted by native keyboard, gamepad, and touch controls.
UserInputService.JumpRequest:Connect(function()
    local current = session
    if not current or current.humanoid.Health <= 0 then
        return
    end

    local now = os.clock()
    if now - current.lastJumpRequestAt < Config.JumpRequestDebounceSeconds then
        return
    end
    current.lastJumpRequestAt = now

    local humanoid = current.humanoid
    if humanoid.FloorMaterial ~= Enum.Material.Air then
        humanoid.Jump = true -- native jump impulse and animation
        current.consumedJump = true
        current.bufferedJumpUntil = -math.huge
    elseif not current.consumedJump and now - current.lastGroundedAt <= Config.CoyoteSeconds then
        -- Just ran off the ledge: apply only a vertical impulse.
        -- Preserve the X/Z velocity earned by the run.
        current.consumedJump = true
        current.bufferedJumpUntil = -math.huge
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        local velocity = current.root.AssemblyLinearVelocity
        local verticalJump = math.sqrt(2 * workspace.Gravity * Config.JumpHeight)
        current.root.AssemblyLinearVelocity = Vector3.new(velocity.X, verticalJump, velocity.Z)
    else
        -- A request just before landing is not lost.
        current.bufferedJumpUntil = now + Config.JumpBufferSeconds
    end
end)

RunService.Heartbeat:Connect(function(dt)
    local current = session
    if not current or current.humanoid.Health <= 0 then
        return
    end

    local humanoid = current.humanoid
    local now = os.clock()
    local grounded = humanoid.FloorMaterial ~= Enum.Material.Air

    if grounded then
        current.lastGroundedAt = now
        if not current.wasGrounded then
            current.consumedJump = false
            if current.bufferedJumpUntil >= now then
                current.bufferedJumpUntil = -math.huge
                current.consumedJump = true
                humanoid.Jump = true
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
    if humanoid:GetState() == Enum.HumanoidStateType.Jumping then
        current.consumedJump = true
    end
    current.wasGrounded = grounded

    local direction = humanoid.MoveDirection
    local moving = direction.Magnitude > 0.05
    local reversed = grounded and moving and current.lastDirection.Magnitude > 0.05
        and direction:Dot(current.lastDirection) < -0.2

    current.charge = MovementMath.nextCharge(
        current.charge, dt, moving, grounded, reversed, Config
    )
    if grounded then
        current.lastDirection = if moving then direction else Vector3.zero
    end

    humanoid.WalkSpeed = MovementMath.speedFromCharge(current.charge, Config)
    humanoid:SetAttribute("MageSlayerRunCharge", current.charge)
end)
