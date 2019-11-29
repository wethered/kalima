


# KALIMA - Bootstraping a fresh Kali VM (Release: 2019.3)

![](https://media0.giphy.com/media/MxqPlIC8TmbPW/giphy.gif)

Let's get things straight:

1. This is just a small script to create "per project" ephimeral VMs
2. No I am not using anything fancy such as Ansible for a simple reason: it's an overkill for a simple, single use VM I'll wipe in a few months.
3. I *don't* take feature requests, fork it and play with it.

__Assumptions:__ There is a directory on your host system with the same name as your project name and it will be mounted to the VM using the same name. This way project data can be exchanged easily between Host and project VM.

__Example use:__

![](https://31337.wtf/kalima/kalima-bootstrap.png)


__Kalima Script:__
![](https://31337.wtf/kalima/kalima-script.png)


__Kalima Script - Silencer:__
![](https://31337.wtf/kalima/kalima-silencer.png)

![Before Silencer](https://31337.wtf/kalima/kalima-before-silencer.png)
![After Silencer](https://31337.wtf/kalima/kalima-after-silencer.png)
