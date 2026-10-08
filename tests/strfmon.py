"""Print strfmon(FORMAT, VALUE) in the current locale.

Python's locale.currency() ignores the int_* precedence fields, so call
glibc's strfmon directly to see exactly what C programs get.
"""
import ctypes
import locale
import sys

locale.setlocale(locale.LC_ALL, "")
libc = ctypes.CDLL(None)
buf = ctypes.create_string_buffer(256)
fmt, value = sys.argv[1], float(sys.argv[2])
if libc.strfmon(buf, ctypes.c_size_t(len(buf)), fmt.encode(), ctypes.c_double(value)) < 0:
    sys.exit("strfmon failed")
sys.stdout.buffer.write(buf.value + b"\n")
