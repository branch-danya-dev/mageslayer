-- M0.1 movement tuning. Bhop is baseline; advanced air skills still belong to magic.
return {
    BaseRunSpeed = 20,
    MaxRunSpeed = 30, -- meaningful acceleration: +50% over 2 seconds
    RunChargeSeconds = 2.0,
    RunChargeDecayPerSecond = 2.5,
    ReverseChargePenalty = 0.55,

    JumpHeight = 8,
    CoyoteSeconds = 0.10,
    JumpBufferSeconds = 0.12,
    JumpRequestDebounceSeconds = 0.12,

    -- A jump pushes the player along the charge curve.
    JumpChargeGain = 0.14,
    FirstHopBonus = 0.7,
    ChainedHopBonus = 1.05,
    HopBonusCap = 6,
    HopChainWindow = 0.24, -- jump shortly after landing for the next chain
    HopBonusGroundDecay = 7, -- speed bonus fades if you stay on the ground
    HopBonusStopDecay = 20,
    JumpTakeoffImpulse = 1.25, -- speed nudge at takeoff, no direction change

    FirstPersonFov = 80,
    MaxSpeedFovBonus = 10, -- fisheye-like perspective widening, not a lens shader
    FovResponse = 8,
    JumpFovPulse = 2.2,
    JumpFovRecovery = 8,
    StrafeLeanDegrees = 0.65,
    EnableHeadBob = true,
    HeadBobAmplitude = 0.018,
    HeadBobFrequency = 10,
    LandingDip = 0.11,
    LandingPitchDegrees = 1.2,
    LandingRecovery = 12
}
