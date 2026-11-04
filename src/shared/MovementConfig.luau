-- M0: the baseline kit contains no magical/advanced movement abilities.
return {
    BaseRunSpeed = 20, -- studs/s; movement starts in sprint mode
    MaxRunSpeed = 25,
    RunChargeSeconds = 2.0,
    RunChargeDecayPerSecond = 2.5, -- stopping clears charge in ~0.4s
    ReverseChargePenalty = 0.55,

    JumpHeight = 8, -- studs
    CoyoteSeconds = 0.10,
    JumpBufferSeconds = 0.12,
    JumpRequestDebounceSeconds = 0.12,

    FirstPersonFov = 80,
    MaxSpeedFovBonus = 3,
    FovResponse = 8,
    EnableHeadBob = true,
    HeadBobAmplitude = 0.018, -- studs, intentionally subtle
    HeadBobFrequency = 10,
    LandingDip = 0.11,
    LandingPitchDegrees = 1.2,
    LandingRecovery = 12
}
