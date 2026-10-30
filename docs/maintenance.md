# Maintenance

This repository holds the publication assets, local draft tools, and reviewed archive for **This Week in Obsidian**. Collection and generation belong in `gen-newsletter-obsidian`; its `output/templates/formatted_template.md` is the sole content template.

## Drafts and archives

The newsletter is published every Tuesday at [This Week in Obsidian on Substack](https://thisweekinobsidian.substack.com/).

Use Bash and the system `date` command on macOS or Linux to create an empty draft:

```sh
bash scripts/newsletter.sh new 2026-11-10
```

The helper assigns the next issue number and requires a Tuesday. With no date argument, it chooses the next Tuesday, including when run on a Tuesday. Copy the generator's reviewed Formatted output into the empty file, then edit it manually. Drafts and their attachments are ignored by Git.

After publication, archive the matching draft with:

```sh
bash scripts/newsletter.sh archive YYYY-MM-DD-issue-NN.md
```

The filename date should match the actual publication date. Only regular files in `drafts/` with valid issue filenames and calendar dates can be archived. Existing archive files are protected from replacement.

## Assets

- `assets/avatar.png`: the current purple faceted TWO logo used by the publication, preserved at its native resolution.
- `assets/banner.png`: the selected humanist serif README banner with the purple crystal and note illustration.

## Checks

```sh
bash -n scripts/newsletter.sh
python3 -B -m unittest discover -s tests -v
```

The tests use temporary fixtures and do not modify real issues.
