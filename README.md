# en_PL

[![tests](https://img.shields.io/github/actions/workflow/status/mlesniew/en_PL-locale/test.yml?branch=main&label=tests)](https://github.com/mlesniew/en_PL-locale/actions/workflows/test.yml)
[![license](https://img.shields.io/github/license/mlesniew/en_PL-locale)](LICENSE)

An English locale with international formats — ISO 8601 dates, SI number
formatting, 24-hour clock, Monday-first weeks, A4 and metric units — plus the
Polish złoty and Polish alphabetical order. It is the Polish counterpart of
`en_DK`, which many systems ship for the same purpose.

```
$ export LANG=en_PL.UTF-8
$ printf "%'.2f\n" 1234567.891
1 234 567.89
$ python3 -c 'import locale, time; locale.setlocale(locale.LC_ALL, ""); print(time.strftime("%x | %c"))'
2026-10-07 | 2026-10-07 22:11:59 CEST
```

## Install

```sh
git clone https://github.com/mlesniew/en_PL-locale.git
cd en_PL-locale
./install-en_PL.sh                # install or update (asks for sudo)
./install-en_PL.sh --set-default  # also make it the system default
./install-en_PL.sh --uninstall    # remove
```

Works on any glibc system with `localedef` (Debian/Ubuntu, Arch, Fedora/RHEL).
The script is self-contained — copy it alone to another machine.

## Use

Pick *English (Poland)* in GNOME Settings → Region & Language → Formats, or
`export LANG=en_PL.UTF-8`. Log out and back in, and make sure no `LC_*`
variables override it.

## What you get

| Category | Example |
|---|---|
| Numbers | `1 234 567.89` (decimal point, thin-space grouping) |
| Currency | `1 234.56 zł`, `PLN 1 234.56` |
| Date / time | `2026-10-07`, `22:11:59`, weeks start on Monday |
| Sorting | Polish: `az ąb lody łódź zebra źle Żaba` |
| Paper / units | A4, metric |
| Address / phone | Polish formats, `+48` |

**Why a decimal point?** The locale follows SI / ISO 80000 rather than Polish
custom: a decimal comma makes `printf`, `sort -n`, CSV import/export and
`strtod()` disagree with other tools, and a space (never `,` or `.`) is the
only unambiguous thousands separator.

## Tests

`tests/docker.sh` installs, checks and removes the locale in a container for
each supported distribution (needs Docker); pass image names to test only
those, e.g. `tests/docker.sh fedora:latest`. CI runs the same on every push.

## License

[GPL-3.0-or-later](LICENSE)
