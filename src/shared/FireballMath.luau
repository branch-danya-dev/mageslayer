-- Pure utilities for the server-authoritative fireball prototype.
local FireballMath = {}

function FireballMath.canCast(now, lastCast, minimumInterval)
    return now - lastCast >= minimumInterval
end

function FireballMath.advanceDistance(currentDistance, dt, speed, maxDistance)
    local delta = math.max(0, dt) * math.max(0, speed)
    return math.min(math.max(0, maxDistance), currentDistance + delta)
end

function FireballMath.isValidShotId(shotId)
    return type(shotId) == "number"
        and shotId == shotId
        and shotId >= 1
        and shotId <= 1000000000
        and shotId == math.floor(shotId)
end

return FireballMath
