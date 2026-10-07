#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# https://github.com/mlesniew/en_PL-locale
#
# Install en_PL.UTF-8: an English locale for Poland with ISO/SI-style formats.
#
#   numbers   1 234 567.89   (SI: decimal point, narrow no-break space grouping)
#   money     1 234.56 zł / PLN 1 234.56 (negative: -1 234.56 zł / PLN -1 234.56)
#   dates     2026-10-07, 2026-10-07 22:11:59 CEST (ISO 8601), 24h clock
#   week      Monday first, ISO 8601 week numbering
#   sorting   Polish alphabet; A4 paper; metric units
#
# The definition is self-contained apart from the base glibc locale sources
# (i18n, translit_combining, iso14651_t1, pl_PL), which are shipped as source
# files with glibc even when the corresponding locales are not generated.
#
# Usage:
#   ./install-en_PL.sh               install (or update) the locale
#   ./install-en_PL.sh --set-default also make it the system-wide default LANG
#   ./install-en_PL.sh --uninstall   remove the locale
#   ./install-en_PL.sh --print       print the locale definition and exit
#
# Supported: Debian/Ubuntu (locale-gen), Arch (locale-gen + /etc/locale.gen),
# Fedora/RHEL and others (plain localedef).

set -euo pipefail

NAME=en_PL
LOCALE=en_PL.UTF-8
SRC_DIR=/usr/share/i18n/locales
SUPPORTED_D=/var/lib/locales/supported.d
LOCALE_GEN=/etc/locale.gen

write_definition() {
    cat <<'EOF'
comment_char %
escape_char /

% English locale for Poland with ISO/SI-style formats.
% Installed by install-en_PL.sh.

LC_IDENTIFICATION
title      "English locale for Poland, ISO/SI formats"
source     "https://github.com/mlesniew/en_PL-locale"
address    ""
contact    "Micha<U0142> Le<U015B>niewski"
email      "mlesniew@gmail.com"
tel        ""
fax        ""
language   "English"
territory  "Poland"
revision   "1.1"
date       "2026-10-07"

category "i18n:2012";LC_IDENTIFICATION
category "i18n:2012";LC_CTYPE
category "i18n:2012";LC_COLLATE
category "i18n:2012";LC_TIME
category "i18n:2012";LC_NUMERIC
category "i18n:2012";LC_MONETARY
category "i18n:2012";LC_MESSAGES
category "i18n:2012";LC_PAPER
category "i18n:2012";LC_NAME
category "i18n:2012";LC_ADDRESS
category "i18n:2012";LC_TELEPHONE
category "i18n:2012";LC_MEASUREMENT
END LC_IDENTIFICATION

LC_CTYPE
copy "i18n"

translit_start
include "translit_combining";""
translit_end
END LC_CTYPE

LC_COLLATE
% Polish alphabet: a-ogonek after a, l-stroke after l, z-acute and
% z-dot-above after z, etc.
copy "pl_PL"
END LC_COLLATE

LC_NUMERIC
% SI / ISO 80000-1: decimal point, groups of three separated by
% U+202F NARROW NO-BREAK SPACE
decimal_point   "."
thousands_sep   "<U202F>"
grouping        3
END LC_NUMERIC

LC_MONETARY
int_curr_symbol     "PLN "
currency_symbol     "z<U0142>"
mon_decimal_point   "."
mon_thousands_sep   "<U202F>"
mon_grouping        3
positive_sign       ""
negative_sign       "-"
int_frac_digits     2
frac_digits         2
% local: 1 234.56 zł, -1 234.56 zł
p_cs_precedes       0
p_sep_by_space      1
n_cs_precedes       0
n_sep_by_space      1
p_sign_posn         1
n_sign_posn         1
% international: PLN 1 234.56, PLN -1 234.56
int_p_cs_precedes   1
int_p_sep_by_space  2
int_n_cs_precedes   1
int_n_sep_by_space  2
int_p_sign_posn     4
int_n_sign_posn     4
END LC_MONETARY

LC_TIME
abday   "Sun";"Mon";"Tue";"Wed";"Thu";"Fri";"Sat"
day     "Sunday";/
        "Monday";/
        "Tuesday";/
        "Wednesday";/
        "Thursday";/
        "Friday";/
        "Saturday"
abmon   "Jan";"Feb";/
        "Mar";"Apr";/
        "May";"Jun";/
        "Jul";"Aug";/
        "Sep";"Oct";/
        "Nov";"Dec"
mon     "January";/
        "February";/
        "March";/
        "April";/
        "May";/
        "June";/
        "July";/
        "August";/
        "September";/
        "October";/
        "November";/
        "December"
% ISO 8601 dates, 24-hour clock
d_t_fmt     "%Y-%m-%d %T %Z"
date_fmt    "%Y-%m-%d %T %Z"
d_fmt       "%Y-%m-%d"
t_fmt       "%T"
am_pm       "";""
t_fmt_ampm  ""
% ISO 8601 weeks: Monday first, week 1 contains at least 4 days
week            7;19971130;4
first_weekday   2
first_workday   2
END LC_TIME

LC_MESSAGES
yesexpr "^[+1yYtT]"
noexpr  "^[-0nN]"
yesstr  "yes"
nostr   "no"
END LC_MESSAGES

LC_PAPER
% A4
copy "i18n"
END LC_PAPER

LC_NAME
name_fmt    "%d%t%g%t%m%t%f"
END LC_NAME

LC_ADDRESS
postal_fmt    "%f%N%a%N%d%N%b%N%s %h %e %r%N%z %T%N%c%N"
country_name  "Poland"
country_ab2   "PL"
country_ab3   "POL"
country_num   616
country_car   "PL"
lang_name     "English"
lang_ab       "en"
lang_term     "eng"
lang_lib      "eng"
END LC_ADDRESS

LC_TELEPHONE
tel_int_fmt    "+%c %a %l"
int_prefix     "48"
int_select     "00"
END LC_TELEPHONE

LC_MEASUREMENT
% metric
copy "i18n"
END LC_MEASUREMENT
EOF
}

die() {
    echo "error: $*" >&2
    exit 1
}

warn_overrides() {
    # LC_ALL and LC_* variables take precedence over LANG
    local var found=
    for var in LC_ALL LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY \
               LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE \
               LC_MEASUREMENT LC_IDENTIFICATION; do
        if [ -n "${!var:-}" ] && [ "${!var}" != "$LOCALE" ]; then
            [ -n "$found" ] || echo "note: these variables in your environment override LANG:"
            echo "  $var=${!var}"
            found=1
        fi
    done
    if [ -n "$found" ]; then
        echo "  Remove them from your shell/session startup files" \
             "(e.g. ~/.profile, ~/.bashrc, ~/.zshrc, ~/.pam_environment)."
    fi
}

check_prerequisites() {
    command -v localedef >/dev/null || die "localedef not found"
    local f
    for f in i18n translit_combining iso14651_t1 pl_PL; do
        [ -e "$SRC_DIR/$f" ] || die "$SRC_DIR/$f is missing; install glibc locale sources" \
            "(Debian/Ubuntu: 'locales', Fedora/RHEL: 'glibc-locale-source')"
    done
    [ -e /usr/share/i18n/charmaps/UTF-8 ] || [ -e /usr/share/i18n/charmaps/UTF-8.gz ] \
        || die "UTF-8 charmap is missing; install glibc locale sources"
}

install_locale() {
    check_prerequisites

    echo "Installing $SRC_DIR/$NAME"
    write_definition > "$SRC_DIR/$NAME.tmp"
    chmod 644 "$SRC_DIR/$NAME.tmp"
    mv "$SRC_DIR/$NAME.tmp" "$SRC_DIR/$NAME"

    if [ -d "$SUPPORTED_D" ] && command -v locale-gen >/dev/null; then
        # Ubuntu: entries in supported.d survive package upgrades
        echo "$LOCALE UTF-8" > "$SUPPORTED_D/$NAME"
        locale-gen "$NAME"
    elif [ -f "$LOCALE_GEN" ] && command -v locale-gen >/dev/null; then
        # Debian, Arch
        grep -q "^$LOCALE UTF-8" "$LOCALE_GEN" || echo "$LOCALE UTF-8" >> "$LOCALE_GEN"
        locale-gen
    else
        # Fedora and others: a directory under /usr/lib/locale is not lost
        # when the package manager rebuilds locale-archive
        localedef --no-archive -c -i "$NAME" -f UTF-8 "$LOCALE"
    fi

    LC_ALL=$LOCALE locale -k d_fmt >/dev/null 2>&1 || die "$LOCALE was not generated"
    echo "Installed $LOCALE"
}

set_default() {
    echo "Setting system default LANG=$LOCALE"
    if command -v update-locale >/dev/null; then
        update-locale LANG="$LOCALE"
    elif command -v localectl >/dev/null; then
        localectl set-locale LANG="$LOCALE"
    else
        die "neither update-locale nor localectl found; set LANG=$LOCALE manually"
    fi
}

uninstall_locale() {
    echo "Removing $LOCALE"
    rm -f "$SUPPORTED_D/$NAME"
    if [ -f "$LOCALE_GEN" ]; then
        sed -i "/^#\? *$LOCALE UTF-8/d" "$LOCALE_GEN"
    fi
    rm -f "$SRC_DIR/$NAME"
    rm -rf /usr/lib/locale/en_PL.utf8
    if command -v locale-gen >/dev/null; then
        locale-gen
    elif command -v localedef >/dev/null; then
        localedef --delete-from-archive "$LOCALE" 2>/dev/null || true
    fi
    echo "Removed $LOCALE. Make sure nothing (e.g. /etc/default/locale) still uses it."
}

action=install
set_default=
for arg in "$@"; do
    case "$arg" in
        --print) write_definition; exit 0 ;;
        --uninstall) action=uninstall ;;
        --set-default) set_default=1 ;;
        -h|--help) sed -n '5,/^$/s/^# \{0,1\}//p' "$0"; exit 0 ;;
        *) die "unknown option: $arg (see --help)" ;;
    esac
done

if [ "$(id -u)" -ne 0 ]; then
    # Check the user's environment before sudo replaces it
    [ "$action" = install ] && warn_overrides
    exec sudo "$0" "$@"
fi

if [ "$action" = uninstall ]; then
    uninstall_locale
    exit 0
fi

install_locale
[ -z "$set_default" ] || set_default

cat <<EOF

Done. To use it:
  - GNOME: Settings -> System -> Region & Language -> Formats -> English (Poland)
  - or system-wide: re-run with --set-default (LANG=$LOCALE)
  - or per user: export LANG=$LOCALE
Log out and back in for the change to take effect.
EOF
