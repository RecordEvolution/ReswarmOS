
# Cross Compilation

To cross-compile is to build on one platform a binary that will run on another
platform. When speaking of cross-compilation, it is important to distinguish
between the _build platform_ on which the compilation is performed, and the
_host platform_ on which the resulting executable is expected to run.

Before proceeding with the cross-compilation toolchain setup, get familiar with
the
[GNU Build System](https://www.gnu.org/software/automake/manual/html_node/GNU-Build-System.html),
which unifies configuration, build and installation process for any _GNU project_.
As a result for any package conformal with these guidelines we only have to do

```
./configure && make && make install
```

to configure, build and install the package.

## References

- https://www.gnu.org/software/automake/manual/html_node/Cross_002dCompilation.html
- https://www.gnu.org/software/automake/manual/html_node/Use-Cases.html
