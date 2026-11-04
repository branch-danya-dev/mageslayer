-- Pure calculations; testable without Roblox's character controller.
local MovementMath = {}

function MovementMath.nextCharge(charge, dt, hasInput, isGrounded, reversed, config)
    charge = math.clamp(charge, 0, 1)
    dt = math.clamp(dt, 0, 0.1)

    if not isGrounded then
        return charge
    end

    if reversed then
        charge = math.max(0, charge - config.ReverseChargePenalty)
    end

    if hasInput then
        return math.min(1, charge + dt / config.RunChargeSeconds)
    end

    return math.max(0, charge - dt * config.RunChargeDecayPerSecond)
end

function MovementMath.awardJump(charge, hopBonus, streak, secondsSinceLanding, config)
    -- Only quick consecutive jumps can accumulate a bonus above first-hop speed.
    local chained = streak > 0 and secondsSinceLanding <= config.HopChainWindow
    local nextStreak = if chained then streak + 1 else 1
    local nextBonus = if chained then math.min(config.HopBonusCap, hopBonus + config.ChainedHopBonus)
        else config.FirstHopBonus

    return math.min(1, charge + config.JumpChargeGain), nextBonus, nextStreak
end

function MovementMath.nextHopBonus(bonus, dt, onGround, hasInput, secondsSinceLanding, config)
    if not onGround then
        return math.clamp(bonus, 0, config.HopBonusCap)
    end
    if hasInput and secondsSinceLanding <= config.HopChainWindow then
        return math.clamp(bonus, 0, config.HopBonusCap)
    end
    local decay = if hasInput then config.HopBonusGroundDecay else config.HopBonusStopDecay
    return math.max(0, bonus - math.clamp(dt, 0, 0.1) * decay)
end

function MovementMath.speedFromCharge(charge, hopBonus, config)
    return config.BaseRunSpeed
        + (config.MaxRunSpeed - config.BaseRunSpeed) * math.clamp(charge, 0, 1)
        + math.clamp(hopBonus, 0, config.HopBonusCap)
end

function MovementMath.smoothingAlpha(response, dt)
    return 1 - math.exp(-response * math.max(0, dt))
end

return MovementMath
