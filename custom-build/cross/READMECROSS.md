
# Building gcc (for cross-compilation)

To build a cross-compiler or any compiler for the host system at all, we need
four ingredients:

- linux kernel headers
- binutils
- gcc
- glibc

where gcc itself depends on:

- gmp
- mpfr
- mpc

## binutils

assembler + linker

## gcc

C++ library/compiler


## glic

C library

## Target Triplets

--build=build-type
  the type of system on which the package is being configured and compiled. It
  defaults to the result of running config.guess.
--host=host-type
  the type of system on which the package runs. By default it is the same as the
  build machine. Specifying it enables the cross-compilation mode.
--target=target-type
  the type of system for which any compiler tools in the package produce code
  (rarely needed). By default, it is the same as host.

- https://www.gnu.org/software/autoconf/manual/autoconf-2.68/html_node/Specifying-Target-Triplets.html
- https://www.gnu.org/software/autoconf/manual/autoconf-2.68/html_node/Hosts-and-Cross_002dCompilation.html#Hosts-and-Cross_002dCompilation

## References

- https://gcc.gnu.org/wiki/InstallingGCC
- https://gcc.gnu.org/install/index.html
- https://wiki.osdev.org/Building_GCC
- https://interrupt.memfault.com/blog/gnu-binutils
- https://gcc.gnu.org/install/build.html

!!
- https://preshing.com/20141119/how-to-build-a-gcc-cross-compiler/
- https://gist.github.com/preshing/41d5c7248dea16238b60

host/target specific options

- https://gcc.gnu.org/install/specific.html

Use Docker for multi-architecture builds with "buildx"

- https://www.docker.com/blog/getting-started-with-docker-for-arm-on-linux/

Docker binaries for ARM architecture

- https://docs.docker.com/engine/install/binaries/
- https://download.docker.com/linux/static/stable/

### Articles

- https://medium.com/@darrenjs/building-gcc-from-source-dcc368a3bb70
- https://github.com/darrenjs/howto/tree/master/build_scripts
