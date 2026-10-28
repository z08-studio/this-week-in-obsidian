# This Week in Obsidian

![Banner](assets/banner.png)

**This Week in Obsidian** is a weekly newsletter published every Tuesday, dedicated to tracking the progress and community around [Obsidian](https://obsidian.md/).

It covers official announcements, plugins, tools, community discussions, workflows, and other resources that may be useful to Obsidian users.

[Subscribe on Substack](https://thisweekinobsidian.substack.com) to receive the latest issue in your inbox.

## Drafts and archives

The script runs on macOS and Linux with Bash and the system `date` command.

Create a draft with its intended Tuesday publication date. The script fills in the next issue number and rejects dates that already have a draft or archive:

```sh
bash scripts/newsletter.sh new 2026-10-20
```

Running `bash scripts/newsletter.sh new` without a date creates a draft for the next Tuesday, including when run on a Tuesday.

After publishing, archive the matching draft with `bash scripts/newsletter.sh archive <filename>`. The date in the filename should match the actual publication date on Substack.

Run the draft and archive checks without changing your actual issues:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
```

## Suggest content

Have something useful to share with Obsidian users?

[Submit an issue](https://github.com/z08-studio/this-week-in-obsidian/issues/new?template=content-suggestion.yml) to suggest a plugin, tool, workflow, or community resource for a future edition.
