# checkrun.sh
*CRON-style mailing wrapper (not only) for systemd .timer units*

**(C) 2018, 2019 by Alexander Koch**

## MOTIVATION

Converting my crontabs to systemd .timer units I quickly came across the need of having an equivalent of `MAILTO`, in order to have the output of some jobs mailed somewhere (not only in case of failed runs).

There is a suggestion using `OnFailure=` in the [Arch Wiki](https://wiki.archlinux.org/index.php/Systemd/Timers#MAILTO) but this has the drawback of limited output as well as the fact that it only works for catching failed jobs - nothing done in case of success.

I'm pretty sure systemd will get its own sendmail interface. For the meantime, I wrote a wrapper for providing that functionality.

In fact, checkrun.sh can be seen as a general mailing job wrapper that might get handy for long-running batch jobs on remote machines (e.g. screen sessions) as well. No dependency to systemd at all.

## INSTALLATION

Make sure you have a _sendmail_ binary, or provide a sendmail compatible mail command via `-s` (see below).
Nothing else required (except `wc` and `mktemp` from _coreutils_).

For [Arch Linux](https://archlinux.org) there is a package available in the [AUR](https://aur.archlinux.org/packages/?O=0&K=checkrun). On all other distributions you may use `make install` (as root) to have the script installed as _/usr/bin/checkrun_.

## USAGE

Simply call checkrun.sh instead of the original binary or command you need to run.

In case of a systemd unit, this would make

```
[Service]
ExecStart=/usr/bin/my-service -v -P
```

be changed to

```
[Service]
ExecStart=/usr/bin/checkrun my-service -v -P
```

### Options

checkrun.sh supports the following command line options:

| Option | Argument | Description |
| --- | --- | --- |
| -s | CMD | Use CMD as sendmail binary |
| -m | MAILTO | Set recipient (default: `$USER`) |
| -q | | Do not sent output on exit code 0 |
| -h | | Display usage information


## CONTRIBUTING

Please use the [_Issues_](https://github.com/lynix/checkrun.sh/issues) function to report bugs or problems. Pull requests for improvements or bug fixes are always welcome.

## LICENSE

This work is published under the terms of the MIT License, see file `LICENSE`.
