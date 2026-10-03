import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest

try:
    import yaml
except ImportError:
    yaml = None


ROOT = Path(__file__).resolve().parents[1]


class ReconciledSkillsTest(unittest.TestCase):
    def test_upstream_package_selection(self):
        packages = {"kun": "kunchenguid/kun", "herdr": "herdrdev/herdr"}
        with tempfile.TemporaryDirectory() as directory:
            env = dict(os.environ, HOME=directory, GSTACK_DIR=f"{directory}/gstack")
            for selection in ("kun", "herdr", "all"):
                with self.subTest(selection=selection):
                    result = subprocess.run(
                        ["bash", str(ROOT / "install-upstream.sh"),
                         "--dry-run", "--only", selection],
                        env=env, capture_output=True, text=True, check=True,
                    )
                    commands = [
                        shlex.split(line.strip().removeprefix("(dry-run) "))
                        for line in result.stdout.splitlines()
                        if line.strip().startswith("(dry-run) ")
                    ]
                    installs = [args for args in commands if args[:4] == ["npx", "-y", "skills", "add"]]
                    for skill, repository in packages.items():
                        matches = [args for args in installs if args[4] == repository]
                        expected = selection in (skill, "all")
                        self.assertEqual(len(matches), int(expected))
                        if expected:
                            self.assertEqual(matches[0][5:], [
                                "-g", "-a", "claude-code", "-a", "codex", "-y", "--skill", skill,
                            ])

    def test_gsd_opt_in_quarantines_invite_registrations(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            binary = home / "bin"
            binary.mkdir()
            npx = binary / "npx"
            npx.write_text("#!/bin/sh\nexit 0\n")
            npx.chmod(0o755)
            source = home / "upstream-invite"
            source.mkdir()
            (source / "SKILL.md").write_text("upstream source must survive")
            for client in (".claude", ".agents", ".codex"):
                root = home / client / "skills"
                root.mkdir(parents=True)
                invite = root / "gsd-join-discord"
                if client == ".claude":
                    invite.symlink_to(source, target_is_directory=True)
                elif client == ".codex":
                    invite.symlink_to(home / "missing-source")
                else:
                    invite.mkdir()
                    (invite / "SKILL.md").write_text("invite")
                (root / "gsd-help").mkdir()
            env = dict(os.environ, HOME=str(home), PATH=str(binary) + os.pathsep + os.environ["PATH"])
            command = ["bash", str(ROOT / "install-upstream.sh"), "--only", "gsd"]
            subprocess.run(command + ["--dry-run"], env=env, capture_output=True, check=True)
            self.assertTrue(os.path.lexists(home / ".codex/skills/gsd-join-discord"))
            self.assertFalse((home / ".local/share/skill-retirement").exists())
            subprocess.run(command, env=env, capture_output=True, check=True)
            retirements = list((home / ".local/share/skill-retirement").iterdir())
            self.assertEqual(len(retirements), 1)
            retirement = retirements[0]
            self.assertEqual(len((retirement / "manifest.tsv").read_text().splitlines()), 3)
            for client in (".claude", ".agents", ".codex"):
                self.assertFalse(os.path.lexists(home / client / "skills/gsd-join-discord"))
                self.assertTrue(os.path.lexists(retirement / client / "skills/gsd-join-discord"))
                self.assertTrue((home / client / "skills/gsd-help").is_dir())
            self.assertTrue((retirement / ".claude/skills/gsd-join-discord").is_symlink())
            self.assertEqual((source / "SKILL.md").read_text(), "upstream source must survive")

    @unittest.skipIf(yaml is None, "PyYAML is not installed")
    def test_manifest_and_skill_metadata(self):
        entries = [line.split() for line in (ROOT / "skills.manifest").read_text().splitlines()
                   if line.strip() and not line.lstrip().startswith("#")]
        names = [entry[0] for entry in entries]
        self.assertEqual(len(names), len(set(names)))
        self.assertEqual(set(names), {path.parent.name for path in (ROOT / "skills").glob("*/SKILL.md")})
        self.assertIn(["speed-up-tests", "global"], entries)
        for name, scope in entries:
            with self.subTest(skill=name):
                self.assertIn(scope, ("global", "project"))
                text = (ROOT / "skills" / name / "SKILL.md").read_text()
                self.assertTrue(text.startswith("---\n"))
                metadata = yaml.safe_load(text.split("---", 2)[1])
                self.assertEqual(set(metadata), {"name", "description"})
                self.assertEqual(metadata["name"], name)
                self.assertRegex(name, r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
                self.assertLess(len(name), 64)
                self.assertIsInstance(metadata["description"], str)
                self.assertTrue(metadata["description"].strip())
                self.assertLessEqual(len(metadata["description"]), 1024)
                ui_path = ROOT / "skills" / name / "agents" / "openai.yaml"
                if ui_path.exists():
                    interface = yaml.safe_load(ui_path.read_text())["interface"]
                    for field in ("display_name", "short_description", "default_prompt"):
                        self.assertIsInstance(interface[field], str)
                        self.assertTrue(interface[field].strip())

    def test_speed_up_tests_install_and_uninstall(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "stable"
            source.mkdir()
            shutil.copy(ROOT / "install.sh", source)
            shutil.copy(ROOT / "skills.manifest", source)
            shutil.copytree(ROOT / "skills", source / "skills")
            home = Path(directory) / "home"
            env = dict(os.environ, HOME=str(home))
            command = ["bash", str(source / "install.sh"), "--source-root", str(source)]
            subprocess.run(command, env=env, capture_output=True, text=True, check=True)
            for client in (".claude", ".codex"):
                link = home / client / "skills" / "speed-up-tests"
                self.assertTrue(link.is_symlink())
                self.assertEqual(link.resolve(), (source / "skills" / "speed-up-tests").resolve())
                self.assertTrue((link / "SKILL.md").is_file())
            subprocess.run(command + ["--uninstall"], env=env, capture_output=True, text=True, check=True)
            for client in (".claude", ".codex"):
                self.assertFalse(os.path.lexists(home / client / "skills" / "speed-up-tests"))


if __name__ == "__main__":
    unittest.main()
