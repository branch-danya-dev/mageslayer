-- M1 fireball prototype. Intentionally available without an inventory/equip system.
-- The spell definition is ready for future one- and two-hand variants.
return {
    Id = "Fireball",
    School = "Fire",
    Element = "Fire",
    AllowedHand = "Left", -- only binding implemented in this prototype
    SupportedCastingModes = { OneHand = true, TwoHands = true }, -- metadata only

    CastInterval = 0.30, -- 3.3 casts per second; hold LMB to repeat
    ServerIntervalTolerance = 0.04, -- tolerate small network arrival jitter
    ProjectileSpeed = 175, -- studs/s
    MaxDistance = 145, -- studs
    ProjectileRadius = 0.58,
    BaseDamage = 18, -- placeholder, not balanced
    SpawnOffset = Vector3.new(-1.05, 1.15, -1.8), -- relative to HumanoidRootPart

    -- Public Roblox tutorial sample sound, used as a temporary casting SFX.
    CastSoundId = "rbxassetid://130113322",
    CastSoundVolume = 0.42,
    CastSoundPlaybackSpeed = 0.82,

    FlameTextureId = "rbxassetid://6101261905", -- Roblox particle tutorial asset
    ProjectileCoreColor = Color3.fromRGB(255, 170, 66),
    ProjectileOuterColor = Color3.fromRGB(255, 78, 31),
    ReticleColor = Color3.fromRGB(255, 197, 132)
}
