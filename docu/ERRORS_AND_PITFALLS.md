
# Errors and Pitfalls along the way

## gcc configuration for static compilation

Problem:

```
make[1]: Entering directory '/home/mario/mf-os/sources/gcc-static/mpfr'
CDPATH="${ZSH_VERSION+.}:" && cd ../../gcc-10.2.0/mpfr && /bin/bash /home/mario/mf-os/sources/gcc-10.2.0/mpfr/missing aclocal-1.16 -I m4
 cd ../../gcc-10.2.0/mpfr && /bin/bash /home/mario/mf-os/sources/gcc-10.2.0/mpfr/missing automake-1.16 --gnu
CDPATH="${ZSH_VERSION+.}:" && cd ../../gcc-10.2.0/mpfr && /bin/bash /home/mario/mf-os/sources/gcc-10.2.0/mpfr/missing autoconf
configure:14311: error: possibly undefined macro: AX_PTHREAD
      If this token and others are legitimate, please use m4_pattern_allow.
      See the Autoconf documentation.
make[1]: *** [Makefile:432: ../../gcc-10.2.0/mpfr/configure] Error 1
make[1]: Leaving directory '/home/mario/mf-os/sources/gcc-static/mpfr'
```

Solution:

https://github.com/advancetoolchain/advance-toolchain/issues/521

```
sudo apt-get install autoconf-archive
```