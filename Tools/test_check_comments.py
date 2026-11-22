from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


CHECKER = Path(__file__).with_name("check-comments.py")


class CommentLintTests(unittest.TestCase):
    def test_new_comment_cannot_replace_existing_comment(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tools = root / "Tools"
            tools.mkdir()
            (tools / "check-comments.py").write_bytes(CHECKER.read_bytes())
            source = root / "Sample.swift"
            source.write_text('let url = "https://example.test"\n// old decision\n')
            (root / "Package.swift").write_text("// swift-tools-version: 6.0\n")
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "add", "Sample.swift", "Package.swift"], cwd=root, check=True)
            baseline = subprocess.run(
                [sys.executable, str(tools / "check-comments.py"), "--baseline"],
                cwd=root, check=True, capture_output=True, text=True,
            )
            (tools / "comment-baseline.json").write_text(baseline.stdout)
            self.assertNotIn("Package.swift", baseline.stdout)
            self.assertEqual(subprocess.run(
                [sys.executable, str(tools / "check-comments.py")],
                cwd=root, capture_output=True,
            ).returncode, 0)
            source.write_text('let url = "https://example.test"\n// new decision\n')
            self.assertNotEqual(subprocess.run(
                [sys.executable, str(tools / "check-comments.py")],
                cwd=root, capture_output=True,
            ).returncode, 0)

    def test_python_comment_after_code_is_detected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tools = root / "Tools"
            tools.mkdir()
            (tools / "check-comments.py").write_bytes(CHECKER.read_bytes())
            (tools / "comment-baseline.json").write_text("{}")
            (root / "sample.py").write_text('value = "# text"\nvalue = 1  # added comment\n')
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "add", "sample.py"], cwd=root, check=True)
            result = subprocess.run(
                [sys.executable, str(tools / "check-comments.py")],
                cwd=root, capture_output=True, text=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("sample.py: new comment", result.stderr)

    def test_extensionless_hook_and_gitignore_are_covered(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tools = root / "Tools"
            tools.mkdir()
            (tools / "check-comments.py").write_bytes(CHECKER.read_bytes())
            (tools / "comment-baseline.json").write_text("{}")
            hook = root / ".githooks" / "pre-push"
            hook.parent.mkdir()
            hook.write_text("#!/bin/sh\n# new hook comment\n")
            (root / ".gitignore").write_text("# new ignore comment\n")
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "add", ".githooks/pre-push", ".gitignore"], cwd=root, check=True)
            result = subprocess.run(
                [sys.executable, str(tools / "check-comments.py")],
                cwd=root, capture_output=True, text=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(".githooks/pre-push: new comment", result.stderr)
            self.assertIn(".gitignore: new comment", result.stderr)


if __name__ == "__main__":
    unittest.main()
