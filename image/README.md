

# TODO

- run build process inside docker
- in particular to avoid requirement for root permissions on system due to
   creation of loopback device, partition generation, etc.

instead test it with (does not work either)

```
sudo docker run -it -v /home/mario/Downloads/:/home/root/Downloads ubuntu
```
