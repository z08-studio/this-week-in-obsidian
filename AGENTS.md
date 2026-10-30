# Repository guidelines

- This repository belongs to **This Week In Newsletters**.
- New drafts must be empty files; copy reviewed Formatted output from `gen-newsletter-obsidian` into them. Maintain the content template only in the generator's `output/templates/formatted_template.md`; do not add a local `templates/` directory.
- Keep unpublished drafts ignored. Archive only regular draft files with valid issue filenames, and never replace an existing archive.
- Run `bash -n scripts/newsletter.sh` and `python3 -B -m unittest discover -s tests -v` after changing maintenance tools.
- Commit directly to `main` by default; create a pull request only when the user explicitly requests one.
