-- A temporary M0 greybox for evaluating acceleration, stopping and jumps.
-- Generated once on the server; there is no game loop yet.
local Workspace = game:GetService("Workspace")

if Workspace:FindFirstChild("MovementPlayground") then
    return
end

local arena = Instance.new("Model")
arena.Name = "MovementPlayground"
arena.Parent = Workspace

local function block(name, size, position, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.CanCollide = true
    part.Material = material or Enum.Material.SmoothPlastic
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = arena
    return part
end

local floorColor = Color3.fromRGB(52, 58, 68)
local stepColor = Color3.fromRGB(92, 135, 165)
local jumpColor = Color3.fromRGB(105, 165, 118)

block("MainFloor", Vector3.new(150, 2, 150), Vector3.new(0, -1, 0), floorColor, Enum.Material.Concrete)

local spawn = Instance.new("SpawnLocation")
spawn.Name = "MovementSpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(0, 0.5, 15)
spawn.Anchored = true
spawn.CanCollide = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Color = Color3.fromRGB(180, 181, 185)
spawn.Material = Enum.Material.SmoothPlastic
spawn.Parent = arena

-- Increasing heights: jump height, landing feedback and collision.
block("Step_2", Vector3.new(10, 2, 8), Vector3.new(-24, 1, -25), stepColor)
block("Step_4", Vector3.new(10, 4, 8), Vector3.new(-13, 2, -25), stepColor)
block("Step_6", Vector3.new(10, 6, 8), Vector3.new(-2, 3, -25), stepColor)

-- A corridor with an abrupt turn: braking and reversal test.
block("TurnWallA", Vector3.new(30, 9, 2), Vector3.new(25, 4.5, 25), Color3.fromRGB(94, 101, 116))
block("TurnWallB", Vector3.new(2, 9, 30), Vector3.new(40, 4.5, 10), Color3.fromRGB(94, 101, 116))

-- ~6-stud gaps between islands north of the main floor.
block("GapLandingA", Vector3.new(18, 2, 18), Vector3.new(0, -1, -90), jumpColor)
block("GapLandingB", Vector3.new(18, 2, 18), Vector3.new(0, -1, -114), jumpColor)
block("GapLandingC", Vector3.new(18, 2, 18), Vector3.new(0, -1, -138), jumpColor)
