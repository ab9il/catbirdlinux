# Updating Your Template-based Repository

This is from a comment by [alexliluz](https://github.com/alexliluz) in [a discuttion](https://github.com/ublue-os/bluefin/discussions/4866).

A repository created with **Use this template** does not stay content-linked to the template. GitHub documents that it starts with a single commit and has an unrelated history, unlike a fork. The `template_repository` metadata records the source, but it is not an update channel.

I checked the public `manfredlotz/bluefin-dx-nvidia-open-ml` repository rather than guessing its template age:

- its initial commit is `e7ad05f`, with tree `e4d8277`;
- that tree exactly matches finpilot commit `f2240c52`;
- from `f2240c52` to current `finpilot/main`, the template changed 68 files, including replacement of the build workflow and large changes to `Containerfile`, `Justfile`, `build/`, validation, and maintenance docs;
- a three-way check of that whole delta against the customized repository conflicts in the build workflow, `Containerfile`, `Justfile`, `artifacthub-repo.yml`, `build/10-build.sh`, and other customized files.

So I would **not** use `git merge finpilot/main --allow-unrelated-histories` as the default here. It combines two unrelated project histories and turns a template migration into one very large merge.

There are two different update channels:

1. **Moving dependencies**: keep Renovate enabled. Finpilot's maintenance guide says it updates OCI digests, GitHub Actions SHAs, and pinned tool versions.
2. **Template structure/build logic**: review and port these deliberately through a PR. Renovate cannot synchronize arbitrary `Containerfile`, workflow, or `build/` changes.

For this repository, the exact review commands are:

```bash
git remote add finpilot https://github.com/projectbluefin/finpilot.git
git fetch finpilot main
git switch -c chore/review-finpilot-sync

# Everything the template changed since this repo's exact starting snapshot
git diff --stat f2240c52b1c188a52009fe0d1dffefefd8e86d2a finpilot/main
git diff --name-status f2240c52b1c188a52009fe0d1dffefefd8e86d2a finpilot/main

# Inspect the high-risk areas separately
git diff f2240c52b1c188a52009fe0d1dffefefd8e86d2a finpilot/main -- \
  Containerfile Justfile build/ .github/workflows/ .github/renovate.json

# Downstream customizations that must be preserved
git diff --name-status e7ad05f9748e601b67c97f62d76c1448587e468f main
```

If the `finpilot` remote already exists, skip `git remote add`.

For a small upstream fix, inspect it with `git show --stat <sha>` and cherry-pick that focused commit with `git cherry-pick -x <sha>`, resolving and validating it in the PR. Do not blindly cherry-pick every Renovate commit or changes that switch the base image away from your intended Bluefin variant.

For the current amount of drift, the lower-risk route is to generate a temporary repository from today's finpilot, reapply the downstream customizations shown by the last diff, and run the full build/validation loop. Only migrate the production repository after that clean-template version builds successfully. This gives a readable review of “new template + our customizations” instead of a 68-file unrelated-history merge.

Going forward, record the last reviewed finpilot commit in something like `UPSTREAM.md`. The next review then becomes `git diff <recorded-sha> finpilot/main`, which is repeatable and auditable.

References:

- GitHub template repositories (single initial commit and unrelated history): https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template
- Finpilot maintenance guidance: https://github.com/projectbluefin/finpilot/blob/main/.agents/skills/finpilot-maintain.md
