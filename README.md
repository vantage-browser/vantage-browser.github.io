# Vantage Browser website

Source for [vant.cx](https://vant.cx), generated with
[Nift](https://nift.dev).

## Build

```sh
nift build --all
nift status
```

Editable pages live in `content/`, shared layouts in `templates/`, and static
assets in `public/assets/`. The nested `public` repository contains the site
published by GitHub Pages.

The installation scripts consume the immutable `vant-source.tar.gz`,
`version.txt` and `checksums.txt` assets from the latest tagged
`vantage-browser/vant` GitHub release. Vantage is compiled against the target
system's GTK, WebKitGTK and multimedia libraries before installation.
