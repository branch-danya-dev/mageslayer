local FireballMath = require("../src/shared/FireballMath")

assert(FireballMath.canCast(1.00, -math.huge, 0.30))
assert(not FireballMath.canCast(1.25, 1.00, 0.30))
assert(FireballMath.canCast(1.30, 1.00, 0.30))

assert(FireballMath.advanceDistance(0, 0.1, 175, 145) == 17.5)
assert(FireballMath.advanceDistance(140, 0.1, 175, 145) == 145)
assert(FireballMath.advanceDistance(10, -1, 175, 145) == 10)
assert(FireballMath.advanceDistance(145, 0.1, 175, 145) == 145)

assert(FireballMath.isValidShotId(1))
assert(FireballMath.isValidShotId(1000000000))
assert(not FireballMath.isValidShotId(0))
assert(not FireballMath.isValidShotId(1.1))
assert(not FireballMath.isValidShotId(-1))
assert(not FireballMath.isValidShotId(math.huge))
assert(not FireballMath.isValidShotId(0 / 0))
assert(not FireballMath.isValidShotId("42"))

print("FireballMath: rate limit, range steps and shot IDs PASS")
