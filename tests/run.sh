#!/bin/bash
# Integration tests for install-en_PL.sh. Runs as root inside a disposable
# container (see tests/Dockerfile and tests/docker.sh) — it installs and
# removes the locale for real.

set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
INSTALL=$PWD/install-en_PL.sh
SRC_DIR=/usr/share/i18n/locales
LOCALE=en_PL.UTF-8
NNBSP=$'\xe2\x80\xaf'   # U+202F NARROW NO-BREAK SPACE

# Which install path the script is expected to take on this system
# shellcheck source=/dev/null
. /etc/os-release
case "$ID" in
    ubuntu) FAMILY="supported_d" ;;
    debian|arch) FAMILY="locale_gen" ;;
    fedora|rhel|rocky|almalinux|centos) FAMILY="localedef" ;;
    *) echo "unknown distribution: $ID" >&2; exit 2 ;;
esac
echo "# $PRETTY_NAME ($FAMILY), $(ldd --version | head -n1)"

passed=0
failed=()

ok() {
    echo "ok   - $1"
    passed=$((passed + 1))
}

not_ok() {
    echo "FAIL - $1"
    failed+=("$1")
    shift
    local line
    for line in "$@"; do
        printf '%s\n' "$line" | sed 's/^/       /'
    done
}

# Make U+202F visible in failure messages
show() {
    printf '%s' "$1" | sed "s/$NNBSP/<NNBSP>/g"
}

# expect NAME EXPECTED ACTUAL
expect() {
    if [ "$2" = "$3" ]; then
        ok "$1"
    else
        not_ok "$1" "expected: '$(show "$2")'" "actual:   '$(show "$3")'"
    fi
}

# check NAME COMMAND... — passes when COMMAND succeeds
check() {
    local name=$1 out
    shift
    if out=$("$@" 2>&1); then
        ok "$name"
    else
        not_ok "$name" "$out"
    fi
}

# Run a command in the en_PL locale with a fixed time zone
in_locale() {
    LC_ALL=$LOCALE TZ=Europe/Warsaw "$@"
}

locale_listed() {
    locale -a | grep -qx 'en_PL.utf8'
}

readme_has() {
    local text=${1//$NNBSP/ }
    if grep -qF -- "$text" README.md; then
        ok "README shows '$text'"
    else
        not_ok "README shows '$text'" "not found in README.md"
    fi
}

# --- command line ------------------------------------------------------------

check "--help prints usage" sh -c "'$INSTALL' --help | grep -q 'Usage:'"
"$INSTALL" --bogus >/dev/null 2>&1
expect "unknown option exits with 1" 1 "$?"
check "--print starts with comment_char" sh -c "'$INSTALL' --print | head -n1 | grep -qx 'comment_char %'"

# --- the definition compiles without warnings ----------------------------------

# The installer passes -c to localedef, which hides warnings; compile without
# it here so that any warning fails the test.
tmp=$(mktemp -d)
"$INSTALL" --print > "$tmp/en_PL"
out=$(localedef -i "$tmp/en_PL" -f UTF-8 "$tmp/out" 2>&1)
rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
    ok "definition compiles cleanly"
else
    not_ok "definition compiles cleanly" "localedef exit code $rc" "$out"
fi
rm -rf "$tmp"

# --- missing prerequisites ------------------------------------------------------

mv "$SRC_DIR/pl_PL" /tmp/pl_PL.bak
out=$("$INSTALL" 2>&1)
rc=$?
mv /tmp/pl_PL.bak "$SRC_DIR/pl_PL"
if [ "$rc" -ne 0 ] && grep -q "pl_PL is missing" <<<"$out"; then
    ok "missing pl_PL source is reported"
else
    not_ok "missing pl_PL source is reported" "exit code $rc" "$out"
fi
check "nothing installed after failed prerequisites" test ! -e "$SRC_DIR/en_PL"

# --- install ---------------------------------------------------------------------

check "install succeeds" "$INSTALL"
check "locale -a lists en_PL.utf8" locale_listed
expect "installed source matches --print" "$("$INSTALL" --print)" "$(cat "$SRC_DIR/en_PL")"

case "$FAMILY" in
    supported_d)
        expect "supported.d entry" "$LOCALE UTF-8" "$(cat /var/lib/locales/supported.d/en_PL)"
        ;;
    locale_gen)
        expect "one /etc/locale.gen entry" 1 "$(grep -c "^$LOCALE UTF-8" /etc/locale.gen)"
        ;;
    localedef)
        check "compiled to /usr/lib/locale/en_PL.utf8" test -d /usr/lib/locale/en_PL.utf8
        ;;
esac

# --- locale data -----------------------------------------------------------------

expect "decimal_point" 'decimal_point="."' "$(in_locale locale -k decimal_point)"
expect "thousands_sep" "thousands_sep=\"$NNBSP\"" "$(in_locale locale -k thousands_sep)"
expect "mon_thousands_sep" "mon_thousands_sep=\"$NNBSP\"" "$(in_locale locale -k mon_thousands_sep)"
expect "currency_symbol" 'currency_symbol="zł"' "$(in_locale locale -k currency_symbol)"
expect "d_fmt" 'd_fmt="%Y-%m-%d"' "$(in_locale locale -k d_fmt)"
expect "week" "7 19971130 4" "$(in_locale locale week-ndays week-1stday week-1stweek | tr '\n' ' ' | sed 's/ $//')"
expect "first_weekday" 2 "$(in_locale locale first_weekday)"
expect "paper is A4" "297 210" "$(in_locale locale height width | tr '\n' ' ' | sed 's/ $//')"
expect "measurement is metric" 1 "$(in_locale locale measurement)"
expect "country_ab2" PL "$(in_locale locale country_ab2)"
expect "int_prefix" 48 "$(in_locale locale int_prefix)"
expect "yesexpr" '^[+1yYtT]' "$(in_locale locale yesexpr)"

# --- formatting --------------------------------------------------------------------

number=$(in_locale env printf "%'.2f" 1234567.891)
expect "printf grouping" "1${NNBSP}234${NNBSP}567.89" "$number"

money_local=$(in_locale python3 tests/strfmon.py %n 1234.56)
money_local_neg=$(in_locale python3 tests/strfmon.py %n -1234.56)
money_int=$(in_locale python3 tests/strfmon.py %i 1234.56)
money_int_neg=$(in_locale python3 tests/strfmon.py %i -1234.56)
expect "strfmon %n" "1${NNBSP}234.56 zł" "$money_local"
expect "strfmon %n negative" "-1${NNBSP}234.56 zł" "$money_local_neg"
expect "strfmon %i" "PLN 1${NNBSP}234.56" "$money_int"
expect "strfmon %i negative" "PLN -1${NNBSP}234.56" "$money_int_neg"

when='2026-10-07 22:11:59'
date_x=$(in_locale date -d "$when" +%x)
time_x=$(in_locale date -d "$when" +%X)
date_c=$(in_locale date -d "$when" +%c)
expect "date %x" 2026-10-07 "$date_x"
expect "date %X" 22:11:59 "$time_x"
expect "date %c" "2026-10-07 22:11:59 CEST" "$date_c"
expect "date %A %B" "Wednesday October" "$(in_locale date -d "$when" '+%A %B')"
expect "date %p is empty" "" "$(in_locale date -d "$when" +%p)"
expect "ISO week %V" 41 "$(in_locale date -d "$when" +%V)"

sorted=$(printf '%s\n' zebra Żaba lody źle az łódź ąb | in_locale sort | tr '\n' ' ' | sed 's/ $//')
expect "Polish collation" "az ąb lody łódź zebra źle Żaba" "$sorted"

# --- README examples match reality -------------------------------------------------

readme_has "$number"
readme_has "$money_local"
readme_has "$money_int"
readme_has "$date_x"
readme_has "$time_x"
readme_has "$date_x | $date_c"
readme_has "$sorted"

# --- reinstall / update --------------------------------------------------------------

check "reinstall succeeds" "$INSTALL"
if [ "$FAMILY" = locale_gen ]; then
    expect "still one /etc/locale.gen entry" 1 "$(grep -c "^$LOCALE UTF-8" /etc/locale.gen)"
fi
echo "stale definition" > "$SRC_DIR/en_PL"
check "update over a stale definition" "$INSTALL"
expect "stale definition replaced" "$("$INSTALL" --print)" "$(cat "$SRC_DIR/en_PL")"

# --- --set-default --------------------------------------------------------------------

case "$ID" in
    debian|ubuntu)
        check "--set-default succeeds" "$INSTALL" --set-default
        check "/etc/default/locale has LANG" grep -qx "LANG=$LOCALE" /etc/default/locale
        ;;
    *)
        # localectl needs a running systemd; check the call it receives
        stub=$(mktemp -d)
        printf '#!/bin/sh\necho "$*" > %s/args\n' "$stub" > "$stub/localectl"
        chmod +x "$stub/localectl"
        check "--set-default succeeds" env PATH="$stub:$PATH" "$INSTALL" --set-default
        expect "--set-default calls localectl" "set-locale LANG=$LOCALE" "$(cat "$stub/args" 2>/dev/null)"
        rm -rf "$stub"
        ;;
esac

# --- uninstall ------------------------------------------------------------------------

check "uninstall succeeds" "$INSTALL" --uninstall
check "locale -a no longer lists en_PL" sh -c "! locale -a | grep -qx en_PL.utf8"
check "source file removed" test ! -e "$SRC_DIR/en_PL"
check "compiled locale removed" test ! -e /usr/lib/locale/en_PL.utf8
check "locale no longer loads" sh -c "! LC_ALL=$LOCALE locale -k d_fmt 2>/dev/null | grep -q Y"
[ ! -e /var/lib/locales/supported.d ] || check "supported.d entry removed" test ! -e /var/lib/locales/supported.d/en_PL
[ ! -e /etc/locale.gen ] || check "/etc/locale.gen entry removed" sh -c "! grep -q '$LOCALE' /etc/locale.gen"
check "second uninstall succeeds" "$INSTALL" --uninstall

# --- install as a regular user via sudo --------------------------------------------------

useradd -m tester
echo 'tester ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tester
chmod 440 /etc/sudoers.d/tester
out=$(sudo -u tester env LC_TIME=C "$INSTALL" 2>&1)
rc=$?
if [ "$rc" -eq 0 ]; then ok "install as regular user via sudo"; else not_ok "install as regular user via sudo" "$out"; fi
if grep -q "LC_TIME=C" <<<"$out"; then ok "overriding LC_* variables are reported"; else not_ok "overriding LC_* variables are reported" "$out"; fi
check "locale -a lists en_PL.utf8 after sudo install" locale_listed

# --- summary --------------------------------------------------------------------------

echo
echo "# $passed passed, ${#failed[@]} failed ($PRETTY_NAME)"
[ "${#failed[@]}" -eq 0 ]
