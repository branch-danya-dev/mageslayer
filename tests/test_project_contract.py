"""Fast structural checks. Physics and subjective feel require Roblox Studio."""

import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHARED = ROOT / "src" / "shared"
CLIENT = ROOT / "src" / "client"


class MovementContractTests(unittest.TestCase):
    def test_rojo_mapping_and_character_defaults(self):
        project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
        tree = project["tree"]
        for folder in ("src/shared", "src/client", "src/server"):
            self.assertTrue((ROOT / folder).is_dir(), folder)
        starter = tree["StarterPlayer"]
        self.assertEqual(starter["$properties"]["CameraMode"], "LockFirstPerson")
        self.assertEqual(starter["$properties"]["CharacterWalkSpeed"], 20)
        self.assertEqual(starter["$properties"]["CharacterJumpHeight"], 8)
        self.assertFalse(starter["$properties"]["CharacterUseJumpPower"])

    def test_agreed_motion_constants(self):
        config = (SHARED / "MovementConfig.luau").read_text(encoding="utf-8")
        for field, expected in (
            ("BaseRunSpeed", "20"),
            ("MaxRunSpeed", "25"),
            ("RunChargeSeconds", "2.0"),
            ("JumpHeight", "8"),
            ("CoyoteSeconds", "0.10"),
            ("JumpBufferSeconds", "0.12"),
        ):
            with self.subTest(field=field):
                self.assertRegex(config, rf"\b{field}\s*=\s*{re.escape(expected)}\b")

    def test_native_input_and_one_jump_guard(self):
        source = (CLIENT / "MovementController.client.luau").read_text(encoding="utf-8")
        for token in (
            "CharacterAdded", "CharacterRemoving", "JumpRequest", "MoveDirection",
            "AssemblyLinearVelocity", "consumedJump", "bufferedJumpUntil",
            "lastGroundedAt", "HumanoidStateType.Jumping", "WalkSpeed",
        ):
            with self.subTest(token=token):
                self.assertIn(token, source)

    def test_camera_preserves_native_look(self):
        source = (CLIENT / "FirstPersonCamera.client.luau").read_text(encoding="utf-8")
        self.assertIn("LockFirstPerson", source)
        self.assertIn("BindToRenderStep", source)
        self.assertIn("Enum.RenderPriority.Camera.Value + 1", source)
        self.assertNotIn("Enum.CameraType.Scriptable", source)

    def test_base_kit_has_no_reserved_abilities(self):
        source = (CLIENT / "MovementController.client.luau").read_text(encoding="utf-8")
        source += (SHARED / "MovementConfig.luau").read_text(encoding="utf-8")
        for ability in ("WallJump", "SlideAbility", "DashAbility", "DoubleJump", "FlightAbility"):
            self.assertNotIn(ability, source)


if __name__ == "__main__":
    unittest.main()
