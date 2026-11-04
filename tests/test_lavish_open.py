import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).parents[1] / "skills/lavish-open/scripts/open_file.py"


class LavishOpenTest(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.root = Path(self.tempdir.name).resolve()
        self.work = self.root / "working directory"
        self.work.mkdir()
        self.sources = self.root / "source files"
        self.sources.mkdir()
        self.receipt = self.root / "opened-path"
        self.bin = self.root / "stub bin"
        self.bin.mkdir()
        self.launcher = self.bin / "lavish-axi"
        self.launcher.write_text(
            '#!/bin/sh\nprintf "%s" "$1" > "$OPENED_PATH"\n'
            'printf "%s\\n" "http://localhost:1234/session/test"\n'
        )
        self.launcher.chmod(0o755)
        self.env = dict(os.environ, OPENED_PATH=str(self.receipt),
                        PATH=f"{self.bin}{os.pathsep}{os.environ.get('PATH', '')}")

    def run_helper(self, name, content, directory=None, **env):
        source = (directory or self.sources) / name
        source.write_text(content)
        result = subprocess.run([sys.executable, str(SCRIPT), str(source)],
                                cwd=self.work, env=dict(self.env, **env),
                                text=True, capture_output=True)
        self.assertEqual(source.read_text(), content)
        return result, source

    def converted(self, name, content, directory=None):
        if not shutil.which("pandoc"):
            self.skipTest("pandoc is required for conversion integration tests")
        result, source = self.run_helper(name, content, directory)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("http://localhost:1234/session/test", result.stdout)
        output = Path(self.receipt.read_text())
        self.assertEqual(output.parent, self.work / ".lavish")
        self.assertFalse((source.parent / ".lavish").exists())
        self.assertIn(str(output), result.stderr)
        self.output = output
        return output.read_text()

    def test_reopen_overwrites_stable_source_derived_output(self):
        self.converted("report.md", "# First")
        first = self.output
        self.assertTrue(first.name.startswith("report-"))
        self.assertIn("<title>Second</title>", self.converted("report.md", "# Second"))
        self.assertEqual(self.output, first)
        other = self.root / "other sources"
        other.mkdir()
        self.converted("report.md", "# Other", other)
        self.assertNotEqual(self.output, first)
        self.assertEqual(len(list((self.work / ".lavish").glob("*.html"))), 2)

    def test_markdown_conversion_title_toc_table_and_theme(self):
        html = self.converted("report with spaces.MD", """```text
# Not the title
```
## A *readable* & useful report

### Details

| Item | Result |
| --- | --- |
| one | passed |
""")
        self.assertIn("<html", html)
        self.assertRegex(html, r"<title>A readable &amp; useful\s+report</title>")
        self.assertIn('id="TOC"', html)
        self.assertIn("<table>", html)
        self.assertIn("prefers-color-scheme:dark", html)
        self.assertIn("--bg:#16181c", html)
        self.assertIn("max-width:46rem", html)
        self.assertIn("Georgia,serif", html)

    def test_setext_heading_and_no_heading_fallback(self):
        self.assertIn("<title>Report title</title>",
                      self.converted("report.md", "Report title\n============\n"))
        self.assertIn("<title>notes.md</title>",
                      self.converted("notes.md", "No heading here."))

    def test_plain_text_is_literal_and_uses_filename(self):
        html = self.converted("notes.txt", "# Literal heading\n<script>bad()</script>\n````\n")
        self.assertIn("<title>notes.txt</title>", html)
        self.assertIn("# Literal heading", html)
        self.assertIn("&lt;script&gt;bad()&lt;/script&gt;", html)
        self.assertNotIn("<script>bad()", html)
        self.assertIn("````", html)

    def test_html_opens_unchanged_without_pandoc(self):
        result, source = self.run_helper("direct.HTML", "<h1>Already HTML</h1>",
                                         PATH=str(self.bin))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.receipt.read_text(), str(source))
        self.assertFalse((self.work / ".lavish").exists())

    def test_missing_dependencies_fail_before_launch(self):
        for overrides, message in [({"PATH": ""}, "Missing lavish-axi"),
                                   ({"PATH": str(self.bin)}, "Missing pandoc")]:
            with self.subTest(message=message):
                result, _ = self.run_helper("report.md", "# Report", **overrides)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(message, result.stderr)
                self.assertFalse(self.receipt.exists())

    def test_unsupported_file_fails_without_launch(self):
        result, _ = self.run_helper("report.pdf", "unsupported")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unsupported file type", result.stderr)
        self.assertFalse(self.receipt.exists())

    def fail_conversion(self, name, content):
        pandoc = self.root / "failing pandoc" / "pandoc"
        pandoc.parent.mkdir(exist_ok=True)
        pandoc.write_text('#!/bin/sh\nfor last; do :; done\nprintf "partial" > "$last"\n'
                          'printf "conversion failed\\n" >&2\nexit 2\n')
        pandoc.chmod(0o755)
        self.receipt.unlink(missing_ok=True)
        result, _ = self.run_helper(name, content, PATH=f"{self.bin}{os.pathsep}{pandoc.parent}")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("conversion failed", result.stderr)
        self.assertFalse(self.receipt.exists())

    def test_conversion_failure_does_not_launch_or_leave_html(self):
        self.fail_conversion("notes.txt", "Plain text")
        self.assertEqual(list((self.work / ".lavish").iterdir()), [])

    def test_failed_reconversion_keeps_previous_html(self):
        previous = self.converted("notes.txt", "First version")
        self.fail_conversion("notes.txt", "Second version")
        self.assertEqual(list((self.work / ".lavish").iterdir()), [self.output])
        self.assertEqual(self.output.read_text(), previous)


if __name__ == "__main__":
    unittest.main()
