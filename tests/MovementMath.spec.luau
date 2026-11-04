-- Pure runtime tests executed by the upstream Luau CLI in GitHub Actions.
local Math = require("../src/shared/MovementMath")
local Config = require("../src/shared/MovementConfig")

local function approx(actual, expected)
    assert(math.abs(actual - expected) < 0.00001, tostring(actual) .. " ~= " .. tostring(expected))
end

local charge = 0
for _ = 1, 20 do
    charge = Math.nextCharge(charge, 0.1, true, true, false, Config)
end
approx(charge, 1)
approx(Math.speedFromCharge(0, 0, Config), 20)
approx(Math.speedFromCharge(charge, 0, Config), 30)

-- The charge holds while airborne, but reversals/idle remove it on ground.
approx(Math.nextCharge(0.7, 0.1, true, false, false, Config), 0.7)
assert(Math.nextCharge(1, 0.1, true, true, true, Config) < 0.6)
assert(Math.nextCharge(0.8, 0.1, false, true, false, Config) < 0.8)

-- First jump accelerates, fast repeated hops stack; delayed hops restart the chain.
local c1, b1, s1 = Math.awardJump(0, 0, 0, math.huge, Config)
approx(c1, Config.JumpChargeGain)
approx(b1, Config.FirstHopBonus)
assert(s1 == 1)

local c2, b2, s2 = Math.awardJump(c1, b1, s1, 0.03, Config)
assert(c2 > c1 and b2 > b1 and s2 == 2)

local _, b3, s3 = Math.awardJump(c2, b2, s2, 0.5, Config)
approx(b3, Config.FirstHopBonus)
assert(s3 == 1)

-- After many well-timed hops, bonus cannot exceed the fixed cap.
local bonus, streak = b2, s2
for _ = 1, 100 do
    local _, nextBonus, nextStreak = Math.awardJump(0.5, bonus, streak, 0.05, Config)
    bonus, streak = nextBonus, nextStreak
end
approx(bonus, Config.HopBonusCap)
approx(Math.speedFromCharge(1, bonus, Config), 36)

-- Bonus is conserved in air, fades when grounded, and decays fastest at rest.
approx(Math.nextHopBonus(4, 0.1, false, true, 0.5, Config), 4)
approx(Math.nextHopBonus(4, 0.1, true, true, 0.05, Config), 4)
assert(Math.nextHopBonus(4, 0.1, true, false, 0.5, Config)
    < Math.nextHopBonus(4, 0.1, true, true, 0.5, Config))

print("MovementMath: charge, hop chains, caps and decay PASS")
