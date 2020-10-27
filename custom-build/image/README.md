
# OS image

To generate a fully prepared SD-card image ready for employment we have basically
to options:

1. setup the image file as _loopback device_, mount it and add the file to the
   boot and root directories
1. using _mtools_ and _mcopy_ in particular to modify the **unmounted** image,
   which is also possible in a container since it does not require root permissions
   in contrast to setting up a loopback device (however, _mtools_ only work on
    _vfat_ file systems, to handle _ext4_ we have to use something like
    _extfstools_)


# TODO

- run build process inside docker
- in particular to avoid requirement for root permissions on system due to
   creation of loopback device, partition generation, etc.

instead test it with (does not work either)

```
sudo docker run -it -v /home/mario/Downloads/:/home/root/Downloads ubuntu
```

## References

- https://www.gnu.org/software/mtools/
- https://en.wikipedia.org/wiki/Mtools
- https://github.com/qmfrederik/extfstools
