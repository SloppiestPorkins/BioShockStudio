"""Unit tests for texture_intent.py, runnable without Unreal."""

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import texture_intent  # noqa: E402


def _entry(file, material, usage, colour_space):
    return {
        "file": file,
        "material": material,
        "usage": usage,
        "colourSpace": colour_space,
    }


class TextureIntentTests(unittest.TestCase):
    def test_single_srgb_diffuse_keeps_bare_stem(self):
        entry = _entry("Textures/med_wall_public_dirt.png", "Wall", "Diffuse", "Srgb")

        result = texture_intent.classify([entry], set())[id(entry)]

        self.assertEqual(result["name"], "med_wall_public_dirt")
        self.assertTrue(result["srgb"])
        self.assertTrue(result["is_primary"])

    def test_diffuse_stays_primary_when_same_stem_is_opacity_mask(self):
        mask = _entry("Textures/shared.png", "Masked", "Diffuse", "Srgb")
        diffuse = _entry("Textures/shared.png", "Wall", "Diffuse", "Srgb")
        result = texture_intent.classify(
            [mask, diffuse], {("Masked", "Textures/shared.png")}
        )

        self.assertEqual(result[id(diffuse)]["name"], "shared")
        self.assertTrue(result[id(diffuse)]["is_primary"])
        self.assertEqual(result[id(mask)]["name"], "shared_mask")
        self.assertFalse(result[id(mask)]["srgb"])
        self.assertFalse(result[id(mask)]["is_primary"])

    def test_only_normal_map_keeps_bare_stem(self):
        entry = _entry("normal.png", "Wall", "NormalMap", "Linear")

        result = texture_intent.classify([entry], set())[id(entry)]

        self.assertEqual(result["name"], "normal")
        self.assertTrue(result["is_primary"])

    def test_non_srgb_colour_reuse_gets_data_suffix(self):
        diffuse = _entry("shared.png", "Wall", "Diffuse", "Srgb")
        data = _entry("shared.png", "Control", "Diffuse", "Linear")
        result = texture_intent.classify([diffuse, data], set())

        self.assertEqual(result[id(diffuse)]["name"], "shared")
        self.assertEqual(result[id(data)]["name"], "shared_data")

    def test_classify_is_deterministic(self):
        entries = [
            _entry("shared.png", "Mask", "Mask", "Linear"),
            _entry("shared.png", "Wall", "Diffuse", "Srgb"),
        ]

        self.assertEqual(
            texture_intent.classify(entries, set()),
            texture_intent.classify(entries, set()),
        )

    def test_first_srgb_diffuse_is_primary(self):
        # The decision prefers sRGB diffuse regardless of earlier non-diffuse entries, but
        # among multiple sRGB diffuse bindings primary means the first one in list order.
        normal = _entry("shared.png", "Normal", "NormalMap", "Linear")
        first = _entry("shared.png", "WallA", "Diffuse", "Srgb")
        second = _entry("shared.png", "WallB", "Diffuse", "Srgb")
        result = texture_intent.classify([normal, first, second], set())

        self.assertEqual(result[id(normal)]["name"], "shared_n")
        self.assertTrue(result[id(first)]["is_primary"])
        self.assertTrue(result[id(second)]["is_primary"])
        self.assertEqual(result[id(first)]["name"], "shared")
        self.assertEqual(result[id(second)]["name"], "shared")


if __name__ == "__main__":
    unittest.main()
