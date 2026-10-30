import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]


class NewsletterScriptTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for directory in ("scripts", "drafts", "archive/2026"):
            (self.root / directory).mkdir(parents=True, exist_ok=True)
        shutil.copy2(REPO_ROOT / "scripts/newsletter.sh", self.root / "scripts/newsletter.sh")
        (self.root / "archive/2026/2026-10-13-issue-43.md").write_text(
            "# This Week in Obsidian #43\n"
        )

    def run_script(self, *args, env=None):
        return subprocess.run(
            ["bash", str(self.root / "scripts/newsletter.sh"), *args],
            cwd=self.root,
            env=env,
            capture_output=True,
            text=True,
        )

    def test_explicit_publication_date_creates_empty_draft(self):
        result = self.run_script("new", "2026-10-20")
        self.assertEqual(result.returncode, 0, result.stderr)
        draft = self.root / "drafts/2026-10-20-issue-44.md"
        self.assertTrue(draft.exists())
        self.assertEqual(draft.read_bytes(), b"")

    def test_default_on_tuesday_still_uses_next_tuesday(self):
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        fake_date = bin_dir / "date"
        fake_date.write_text(
            '#!/bin/bash\n'
            'if [[ "$1" == "+%u" ]]; then\n'
            '    printf "2\\n"\n'
            'elif [[ "$1" == "-d" && "$2" == "+7 days" ]]; then\n'
            '    printf "2026-10-27\\n"\n'
            'else\n'
            '    exec "$NEWSLETTER_TEST_DATE" "$@"\n'
            'fi\n'
        )
        fake_date.chmod(0o755)
        env = dict(os.environ)
        env["NEWSLETTER_TEST_DATE"] = shutil.which("date")
        env["PATH"] = str(bin_dir) + os.pathsep + env["PATH"]
        result = self.run_script("new", env=env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.root / "drafts/2026-10-27-issue-44.md").exists())

    def test_create_and_archive_round_trip(self):
        created = self.run_script("new", "2026-10-20")
        self.assertEqual(created.returncode, 0, created.stderr)
        draft = self.root / "drafts/2026-10-20-issue-44.md"
        draft.write_text("# Reviewed Formatted output\n\n- [A reviewed item](https://example.com/)\n")
        content = draft.read_text()

        archived = self.run_script("archive", draft.name)
        self.assertEqual(archived.returncode, 0, archived.stderr)
        self.assertFalse(draft.exists())
        self.assertEqual(
            (self.root / "archive/2026/2026-10-20-issue-44.md").read_text(),
            content,
        )

    def test_existing_draft_or_archive_prevents_duplicate_date(self):
        for directory in ("drafts", "archive/2026"):
            with self.subTest(directory=directory):
                existing = self.root / directory / "2026-10-20-issue-44.md"
                existing.write_text("Existing issue\n")
                result = self.run_script("new", "2026-10-20")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("already exists", result.stderr)
                self.assertEqual(existing.read_text(), "Existing issue\n")
                self.assertFalse((self.root / "drafts/2026-10-20-issue-45.md").exists())
                existing.unlink()

    def test_invalid_dates_leave_drafts_empty(self):
        for publication_date in ("2026-02-30", "2026-10-21", "2026-1-6", "tomorrow"):
            with self.subTest(publication_date=publication_date):
                result = self.run_script("new", publication_date)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(list((self.root / "drafts").iterdir()), [])

    def test_future_draft_still_blocks_earlier_publication_date(self):
        existing = self.root / "drafts/2026-10-27-issue-44.md"
        existing.write_text("Future draft\n")
        result = self.run_script("new", "2026-10-20")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("dated after 2026-10-20", result.stdout)
        self.assertEqual(existing.read_text(), "Future draft\n")
        self.assertEqual(list((self.root / "drafts").iterdir()), [existing])


if __name__ == "__main__":
    unittest.main()
