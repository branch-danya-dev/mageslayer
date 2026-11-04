-- M0.1: native Humanoid motion with noticeable ground charge and an arcade bhop chain.
-- Space/ButtonA held = auto-hop at landing; tap timing and mobile JumpRequest still work.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("MovementConfig"))
local MovementMath = require(ReplicatedStorage:WaitForChild("MovementMath"))

local session = nil
local stateChangedConnection = nil

local function jumpHeld()
    if UserInputService:GetFocusedTextBox() then
        return false
    end
    return UserInputService:IsKeyDown(Enum.KeyCode.Space)
        or (UserInputService.GamepadEnabled
            and UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA))
end

local function detachCharacter()
    if stateChangedConnection then
        stateChangedConnection:Disconnect()
        stateChangedConnection = nil
    end
    session = nil
end

local function markLanded(current)
    if not current.inAir then
        return
    end
    current.inAir = false
    current.lastLandedAt = os.clock()
    current.consumedJump = false
    current.awardedThisJump = false
    current.landingPending = true
end

local function awardTakeoff(current)
    if current.awardedThisJump then
        return
    end
    current.awardedThisJump = true
    current.consumedJump = true
    current.landingPending = false

    local root = current.root
    local velocity = root.AssemblyLinearVelocity
    local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
    local hasMomentum = horizontal.Magnitude > 5 and current.humanoid.MoveDirection.Magnitude > 0.1

    if hasMomentum then
        current.charge, current.hopBonus, current.hopStreak = MovementMath.awardJump(
            current.charge, current.hopBonus, current.hopStreak,
            os.clock() - current.lastLandedAt, Config
        )

        local targetSpeed = MovementMath.speedFromCharge(current.charge, current.hopBonus, Config)
        local boostedSpeed = math.min(targetSpeed, horizontal.Magnitude + Config.JumpTakeoffImpulse)
        if boostedSpeed > horizontal.Magnitude then
            local boosted = horizontal.Unit * boostedSpeed
            root.AssemblyLinearVelocity = Vector3.new(boosted.X, velocity.Y, boosted.Z)
        end
        current.humanoid.WalkSpeed = targetSpeed
    else
        current.hopStreak = 0
    end

    current.humanoid:SetAttribute("MageSlayerJumpPulse", os.clock())
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
        hopBonus = 0,
        hopStreak = 0,
        lastDirection = Vector3.zero,
        wasGrounded = grounded,
        lastGroundedAt = if grounded then os.clock() else -math.huge,
        lastLandedAt = -math.huge,
        inAir = not grounded,
        landingPending = false,
        consumedJump = false,
        awardedThisJump = false,
        bufferedJumpUntil = -math.huge,
        lastJumpRequestAt = -math.huge
    }

    humanoid:SetAttribute("MageSlayerRunCharge", 0)
    humanoid:SetAttribute("MageSlayerHopStreak", 0)
    humanoid:SetAttribute("MageSlayerJumpPulse", 0)

    stateChangedConnection = humanoid.StateChanged:Connect(function(_, newState)
        local current = session
        if not current or current.humanoid ~= humanoid then
            return
        end
        if newState == Enum.HumanoidStateType.Jumping then
            current.inAir = true
            awardTakeoff(current)
        elseif newState == Enum.HumanoidStateType.Freefall then
            current.inAir = true
        elseif newState == Enum.HumanoidStateType.Landed then
            markLanded(current)
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
    if humanoid.FloorMaterial ~= Enum.Material.Air and not current.consumedJump then
        humanoid.Jump = true
        current.consumedJump = true
        current.bufferedJumpUntil = -math.huge
    elseif not current.consumedJump and now - current.lastGroundedAt <= Config.CoyoteSeconds then
        -- Coyote jump preserves current X/Z, including the hop bonus.
        current.consumedJump = true
        current.bufferedJumpUntil = -math.huge
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        local velocity = current.root.AssemblyLinearVelocity
        local jumpY = math.sqrt(2 * workspace.Gravity * Config.JumpHeight)
        current.root.AssemblyLinearVelocity = Vector3.new(velocity.X, jumpY, velocity.Z)
    else
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
            markLanded(current) -- backup if the short Landed state was missed
        end
        if current.landingPending then
            current.landingPending = false
            if (jumpHeld() or current.bufferedJumpUntil >= now)
                and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
                current.bufferedJumpUntil = -math.huge
                current.consumedJump = true
                humanoid.Jump = true
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
    current.wasGrounded = grounded

    local direction = humanoid.MoveDirection
    local moving = direction.Magnitude > 0.05
    local reversed = grounded and moving and current.lastDirection.Magnitude > 0.05
        and direction:Dot(current.lastDirection) < -0.2

    current.charge = MovementMath.nextCharge(
        current.charge, dt, moving, grounded, reversed, Config
    )
    current.hopBonus = MovementMath.nextHopBonus(
        current.hopBonus, dt, grounded, moving, now - current.lastLandedAt, Config
    )
    if reversed then
        current.hopBonus *= 0.5
        current.hopStreak = 0
    end
    if grounded then
        current.lastDirection = if moving then direction else Vector3.zero
        if now - current.lastLandedAt > Config.HopChainWindow then
            current.hopStreak = 0
        end
    end

    humanoid.WalkSpeed = MovementMath.speedFromCharge(current.charge, current.hopBonus, Config)
    humanoid:SetAttribute("MageSlayerRunCharge", current.charge)
    humanoid:SetAttribute("MageSlayerHopStreak", current.hopStreak)
end)
