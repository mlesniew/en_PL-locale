# en_PL — English locale for Poland with ISO/SI formats

A glibc locale for people who use their Linux system in English, live in
Poland, and prefer international, technical and scientific conventions over
the US (or Polish) defaults: ISO 8601 dates, SI number formatting, a 24-hour
clock, weeks starting on Monday, A4 paper and metric units. The only
Poland-specific parts are the currency (PLN, zł), the Polish alphabetical
order and the address and phone conventions.

It is meant as a better alternative to the common workaround of using
`en_DK.UTF-8` (which comes with Danish kroner) or mixing several `LC_*`
variables.

```
$ export LANG=en_PL.UTF-8
$ printf "%'.2f\n" 1234567.891
1 234 567.89
$ python3 -c 'import locale, time; locale.setlocale(locale.LC_ALL, ""); print(time.strftime("%x | %c"))'
2026-10-07 | 2026-10-07 22:11:59 CEST
$ python3 -c 'import locale; locale.setlocale(locale.LC_ALL, ""); print(locale.currency(-1234.5, grouping=True))'
-1 234.50 zł
```

## Installation

```sh
git clone https://github.com/mlesniew/en_PL-locale.git
cd en_PL-locale
./install-en_PL.sh
```

The script asks for `sudo` itself. It installs the locale source as
`/usr/share/i18n/locales/en_PL` and generates `en_PL.UTF-8`. It works on
Debian, Ubuntu, Arch and Fedora/RHEL, and any other glibc system with
`localedef`. Running it again updates an existing installation. The definition
is built into the script, so the script file alone is enough to install the
locale on another machine. It needs only the glibc locale sources, which are
normally installed (Debian/Ubuntu: `locales`, Fedora/RHEL:
`glibc-locale-source`). `en_DK`, `pl_PL` or any other locale don't need to be
generated.

| Command | Effect |
|---|---|
| `./install-en_PL.sh` | install or update the locale |
| `./install-en_PL.sh --set-default` | also set `LANG=en_PL.UTF-8` system-wide |
| `./install-en_PL.sh --uninstall` | remove the locale |
| `./install-en_PL.sh --print` | print the locale definition |

To use the locale:

- **GNOME:** Settings → System → Region & Language → Formats → *English (Poland)*
- **System-wide:** `./install-en_PL.sh --set-default`
- **Per user or per shell:** `export LANG=en_PL.UTF-8`

Then log out and back in. Make sure no `LC_*` or `LC_ALL` variables in your
startup files (`~/.profile`, `~/.bashrc`, `~/.zshrc`, `~/.pam_environment`)
override it. The installer warns about any it finds in the current
environment.

## Settings

| Category | Setting | Example |
|---|---|---|
| `LC_NUMERIC` | decimal point, thin-space grouping | `1 234 567.89` |
| `LC_MONETARY` | local format | `1 234.56 zł`, `-1 234.56 zł` |
| | international format | `PLN 1 234.56`, `PLN -1 234.56` |
| `LC_TIME` | date (`%x`) | `2026-10-07` |
| | time (`%X`), 24-hour clock | `22:11:59` |
| | date and time (`%c`) | `2026-10-07 22:11:59 CEST` |
| | day and month names | `Wed`, `Wednesday`, `Oct`, `October` |
| | week | Monday first, ISO 8601 week numbers |
| `LC_COLLATE` | Polish alphabetical order | `az ąb lody łódź zebra źle Żaba` |
| `LC_PAPER` | A4 | 210 × 297 mm |
| `LC_MEASUREMENT` | metric | |
| `LC_MESSAGES` | yes/no answers | `yes`/`no`; accepts `y` and `t` (Polish *tak*) |
| `LC_CTYPE` | standard Unicode character classes, transliteration | `Łódź` → `Lodz` |
| `LC_ADDRESS` | Polish postal format, country *Poland* | |
| `LC_TELEPHONE` | Polish phone format | `+48 …` |
| `LC_NAME` | given name followed by family name | |

### Design decisions

This is meant to be an **international, technical and scientific** locale,
not a translation of Polish conventions into English. Where the two differ,
it follows the international standard.

**Decimal point, not comma.** In Poland, and in most of continental Europe,
the comma is the usual decimal separator. This locale uses the point
anyway. ISO 80000-1 and the SI Brochure accept it, and it is the norm in
English-language science, engineering and computing. It is also practical: a
locale with a decimal comma makes some programs read or write numbers
differently from everything else. Examples are `printf` in the shell,
`sort -n`, spreadsheet CSV import and export, and programs that parse numbers
with `strtod()`. That causes subtle bugs when data moves between tools, and
with a decimal point the problem doesn't arise.

**Thin space for thousands, not comma or dot.** The SI Brochure and
ISO 80000-1 say that digits may be grouped in threes with a space, and that
neither dots nor commas are ever used for grouping, because `1.234` and
`1,234` mean different things in different countries. Polish typography
agrees. The separator is U+202F NARROW NO-BREAK SPACE, so a number never
breaks across lines. glibc inserts it only when a program asks for grouping
(e.g. `printf "%'d"`).

**ISO 8601 dates (`2026-10-07`).** This is the most unambiguous date format:
nobody reads it as day-month or as month-day, it sorts correctly as plain
text, and it is the international standard (in Poland: PN-EN 28601). Date
and time are separated by a space rather than `T` for readability, as
RFC 3339 allows.

**Currency.** The local format follows Polish usage, with the symbol after
the amount like an SI unit (`1 234.56 zł`). The international format puts the
ISO 4217 code first, as in financial and EU usage, and keeps the minus sign
attached to the number (`PLN -1 234.56`).

## Limitations

- **Only programs that use glibc locale data see these settings.** These
  include the shell and command-line tools, GTK/GNOME applications, Python,
  Perl and C programs. Browsers, Electron applications, Qt/KDE, Java and
  LibreOffice use their own locale data (mostly Unicode CLDR) and take only
  the locale *name* from the system. Most of them recognise `en_PL` as
  *English (Poland)* from CLDR, which is close but not identical. Set
  formats in those applications' own preferences if needed.
- **`ls -l`** has its own time format. Set `TIME_STYLE=long-iso` for ISO
  timestamps.
- **The Rust-based coreutils** used by newer Ubuntu releases ignore the
  locale's `%x` date format in `date`.
- **X11 Compose:** libX11 doesn't know the name `en_PL`. If the Compose key
  or dead keys stop working in older X11 applications, set
  `LC_CTYPE=en_US.UTF-8`. The character data is the same, so nothing else
  changes.

## License

[GPL-3.0-or-later](LICENSE)
