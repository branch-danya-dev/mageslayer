-- Pure calculations; no Roblox instances or physics side effects.
local MovementMath = {}

function MovementMath.nextCharge(charge, dt, hasInput, isGrounded, reversed, config)
    charge = math.clamp(charge, 0, 1)
    dt = math.clamp(dt, 0, 0.1) -- no instant acceleration after a frame stall

    if not isGrounded then
        return charge -- airborne time neither grants nor spends acceleration
    end

    if reversed then
        charge = math.max(0, charge - config.ReverseChargePenalty)
    end

    if hasInput then
        return math.min(1, charge + dt / config.RunChargeSeconds)
    end

    return math.max(0, charge - dt * config.RunChargeDecayPerSecond)
end

function MovementMath.speedFromCharge(charge, config)
    return config.BaseRunSpeed
        + (config.MaxRunSpeed - config.BaseRunSpeed) * math.clamp(charge, 0, 1)
end

function MovementMath.smoothingAlpha(response, dt)
    return 1 - math.exp(-response * math.max(0, dt))
end

return MovementMath
