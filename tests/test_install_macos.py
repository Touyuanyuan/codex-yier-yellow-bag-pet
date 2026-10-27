"""Run on macOS/Linux with python3 -m unittest discover -s tests -p 'test_*macos.py'."""
import importlib.util
import json
import os
import platform
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parent.parent


@unittest.skipUnless(os.name == "posix", "Requires a Unix shell; run on macOS CI")
class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="yier-macos-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.package = self.base / "中文 package with spaces"
        self.package.mkdir()
        for name in ("install.sh", "install.command"):
            shutil.copyfile(ROOT / name, self.package / name)
        shutil.copytree(ROOT / "pet", self.package / "pet")
        self.home = self.base / "test home"
        self.env = dict(os.environ, HOME=str(self.home))
        self.env.pop("CODEX_HOME", None)

    def run_install(self, *args, expected=0, env=None):
        result = subprocess.run(["/bin/bash", str(self.package / "install.sh"), *args],
                                env=env or self.env, cwd="/", capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def test_default_and_repeat_install(self):
        self.run_install()
        target = self.home / ".codex/pets/yier-yellow-bag"
        for name in ("pet.json", "spritesheet.webp"):
            self.assertEqual((target / name).read_bytes(), (ROOT / "pet" / name).read_bytes())
        stamp = (target / "pet.json").stat().st_mtime_ns
        self.assertIn("Already installed", self.run_install().stdout)
        self.assertEqual((target / "pet.json").stat().st_mtime_ns, stamp)

    def test_environment_and_explicit_home_precedence(self):
        env_home = self.base / "environment home"
        self.env["CODEX_HOME"] = str(env_home)
        self.run_install()
        self.assertTrue((env_home / "pets/yier-yellow-bag/pet.json").is_file())
        explicit = self.base / "explicit home"
        self.run_install(str(explicit))
        self.assertTrue((explicit / "pets/yier-yellow-bag/pet.json").is_file())
        self.assertFalse(self.home.exists())

    def test_existing_different_pet_and_other_pets_are_preserved(self):
        target = self.home / ".codex/pets/yier-yellow-bag"
        target.mkdir(parents=True)
        (target / "pet.json").write_text("do not overwrite")
        other = target.parent / "other-pet"
        other.mkdir()
        (other / "keep.txt").write_text("keep")
        self.run_install(expected=2)
        self.assertEqual((target / "pet.json").read_text(), "do not overwrite")
        self.assertEqual((other / "keep.txt").read_text(), "keep")

    def test_missing_payload_stops_before_writing(self):
        (self.package / "pet/spritesheet.webp").unlink()
        self.run_install(expected=1)
        self.assertFalse(self.home.exists())

    def test_symlink_destination_is_preserved(self):
        outside = self.base / "outside"
        outside.mkdir()
        pets = self.home / ".codex/pets"
        pets.mkdir(parents=True)
        (pets / "yier-yellow-bag").symlink_to(outside, target_is_directory=True)
        self.run_install(expected=1)
        self.assertEqual(list(outside.iterdir()), [])

    def test_blank_or_extra_arguments_rejected(self):
        self.run_install("", expected=1)
        self.run_install("one", "two", expected=1)
        self.assertFalse(self.home.exists())

    def test_shell_syntax(self):
        for name in ("install.sh", "install.command"):
            subprocess.run(["/bin/bash", "-n", str(self.package / name)], check=True)

    @unittest.skipUnless(platform.system() == "Darwin", "Uses native macOS plutil")
    def test_invalid_manifest_rejected_on_macos(self):
        path = self.package / "pet/pet.json"
        pet = json.loads(path.read_text())
        pet["spriteVersionNumber"] = 1
        path.write_text(json.dumps(pet))
        self.run_install(expected=1)
        self.assertFalse(self.home.exists())


class PackageTests(unittest.TestCase):
    def test_zip_has_executable_lf_scripts_and_original_payload(self):
        spec = importlib.util.spec_from_file_location("build_macos", ROOT / "tools/build-macos-release.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        archive_path = module.build()
        with zipfile.ZipFile(archive_path) as archive:
            for name in ("install.command", "install.sh"):
                info = archive.getinfo(f"{module.PREFIX}/{name}")
                self.assertEqual((info.external_attr >> 16) & 0o777, 0o755)
                self.assertNotIn(b"\r", archive.read(info))
            for name in ("pet/pet.json", "pet/spritesheet.webp"):
                self.assertEqual(archive.read(f"{module.PREFIX}/{name}"), (ROOT / name).read_bytes())
            self.assertEqual(len(archive.namelist()), len(module.FILES))


if __name__ == "__main__":
    unittest.main()
