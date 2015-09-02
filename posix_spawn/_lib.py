import pkgutil
import threading

from cffi import FFI
from cffi.verifier import Verifier
import binascii
import sys


def _create_modulename(cdef_sources, source, sys_version):
    """
    This is the same as CFFI's create modulename except we don't include the
    CFFI version.
    """
    key = '\x00'.join([sys_version[:3], source, cdef_sources])
    key = key.encode('utf-8')
    k1 = hex(binascii.crc32(key[0::2]) & 0xffffffff)
    k1 = k1.lstrip('0x').rstrip('L')
    k2 = hex(binascii.crc32(key[1::2]) & 0xffffffff)
    k2 = k2.lstrip('0').rstrip('L')
    return '_posix_spawn_cffi_{0}{1}'.format(k1, k2)


def _compile_module(*args, **kwargs):
    raise RuntimeError(
        "Attempted implicit compile of a cffi module. All cffi modules should "
        "be pre-compiled at installation time."
    )


class LazyLibrary(object):
    def __init__(self, the_ffi):
        self._ffi = the_ffi
        self._lib = None
        self._lock = threading.Lock()

    def __getattr__(self, name):
        self.load()
        return getattr(self._lib, name)

    def load(self):
        if self._lib is None:
            with self._lock:
                if self._lib is None:
                    self._lib = self._ffi.verifier.load_library()


CDEF = pkgutil.get_data('posix_spawn', 'c/cdef.h').decode('ascii')
SOURCE = pkgutil.get_data('posix_spawn', 'c/source.c').decode('ascii')

ffi = FFI()
ffi.cdef(CDEF)
ffi.verifier = Verifier(
    ffi,
    SOURCE,
    modulename=_create_modulename(CDEF, SOURCE, sys.version),
)

# Patch the Verifier() instance to prevent CFFI from compiling the module
ffi.verifier.compile_module = _compile_module
ffi.verifier._compile_module = _compile_module

lib = LazyLibrary(ffi)

__all__ = ('lib', 'ffi')
