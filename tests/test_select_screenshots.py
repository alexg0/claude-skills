import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock


SCRIPT = Path(__file__).parents[1] / "skills" / "ss" / "scripts" / "select_screenshots.py"
SPEC = importlib.util.spec_from_file_location("select_screenshots", SCRIPT)
select_screenshots = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(select_screenshots)


class SelectScreenshotsTest(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.older = self.root / "Screenshot older name with spaces.png"
        self.newer = self.root / "Screenshot newer name with spaces.JPG"
        self.ignored = self.root / "private-note.txt"
        self.unrelated_image = self.root / "vacation-photo.jpg"
        for path in (self.older, self.newer, self.ignored, self.unrelated_image):
            path.touch()
        os.utime(self.older, (100, 100))
        os.utime(self.newer, (200, 200))
        os.utime(self.unrelated_image, (300, 300))

    def tearDown(self):
        self.tempdir.cleanup()

    def test_positive_selector_is_globally_newest_first(self):
        self.assertEqual(
            select_screenshots.select(self.root, 2),
            [self.newer, self.older],
        )

    def test_negative_selector_returns_only_nth_newest(self):
        self.assertEqual(select_screenshots.select(self.root, -2), [self.older])

    def test_out_of_range_does_not_reveal_candidates(self):
        self.assertEqual(select_screenshots.select(self.root, -3), [])

    def test_unrelated_newer_image_is_not_selected(self):
        self.assertEqual(select_screenshots.select(self.root, 1), [self.newer])

    def test_custom_prefix_selects_custom_named_screenshot(self):
        custom = self.root / "Capture 001.png"
        custom.touch()
        os.utime(custom, (400, 400))
        with mock.patch.dict(os.environ, {"SCREENSHOT_NAME_PREFIXES": "capture"}):
            self.assertEqual(select_screenshots.select(self.root, 1), [custom])

    def test_explicit_directory_takes_precedence(self):
        with mock.patch.dict(os.environ, {"SCREENSHOT_DIR": str(self.root)}):
            self.assertEqual(select_screenshots.configured_directory(), self.root)

    def test_zero_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "cannot be zero"):
            select_screenshots.select(self.root, 0)


if __name__ == "__main__":
    unittest.main()
