# Maintaining the catalog

The public website is built from `site/` and published through GitHub Pages when those files change. The GitHub overview stays compact; each card links to a guide page.

- Add tools and screenshots in `site/products.json`. `kind` is `scripts` or `plugins`; IDs must remain stable for existing page links.
- Put covers in `docs/cards/` and the matching file in `site/assets/cards/`. Replace the cover path or add a `screenshots` array when real screenshots are ready.
- Script versions are read live from the shared `index.xml`. SideCurve release downloads are refreshed from its latest GitHub release, with working fallback links in the data.
- `tools/publish_reapack.py` appends new immutable release entries and preserves existing package names and history. Changed scripts with an unchanged version get a patch-version bump. Explicit higher versions are retained. Simple new root Lua scripts with `@description` and `@version` are indexed under Other.
- Existing multi-file packages retain the provided-file layout from their latest indexed version. New multi-file packages should be registered in `index.xml` first so their complete layout is known.
- The publish workflow rebuilds `downloads/ArticulationBox.zip` from an explicit 11-file list. Personal bank files are never included.
- Do not change a package category, package name or installed file names for an ordinary release: these identify existing ReaPack installations.

Shared ReaPack URL: https://raw.githubusercontent.com/andreynovikov86-cmd/ReaScripts/main/index.xml
