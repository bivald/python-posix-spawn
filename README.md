[![Build Status](https://travis-ci.org/projectcalico/python-posix-spawn.svg?branch=master)](https://travis-ci.org/projectcalico/python-posix-spawn)

posix-spawn
===========

This repo contains Python bindings for the low-level Linux `posix_spawn()` and `posix_spawnp()` 
functions via CFFI.

Those functions are similar to a combined `fork()/exec()` but they avoid the need to copy the
kernel's memory management metadata during the `fork()`, only to throw it away with the `exec()`.

Since users of `fork()` typically need to manipulate file descriptors, in the child process, 
between `fork()` and `exec()`, `posix_spawn()` provides a mechanism to queue up operations on
file descriptors to be executed in the child process before the child program is executed.
This is provided by the `FileActions` class.  For example, to redirect `stdout` to the parent 
via a pipe:

```python
from posix_spawn import *
import os
# Create the pipe.
c2pread, c2pwrite = os.pipe()
# Tell posix_spawn to replace the child's stdout with the write end of the pipe.
file_actions = FileActions()
file_actions.add_dup2(c2pwrite, 1)
# Close the parent's end of the pipe in the child.
file_actions.add_close(c2pread)
# Execute the child process.  posix_spawnp resolves the path.
pid = posix_spawnp("echo", ["echo", "Hello world!"], file_actions=file_actions)
# Close the child's end of the socket in the parent.
os.close(c2pwrite)
# Replace FD with a file object.
f = os.fdopen(c2pread, "r")
# And get the output.
f.read()  # Returns "Hello world!\n"
# Clean up the child process.
os.waitpid(pid, 0)  # Returns (pid, <returncode>)
f.close()
```
