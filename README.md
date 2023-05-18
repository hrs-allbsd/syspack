# Syspack - System Management Framework based on BSD Make

***
NOTE: This software is still an alpha version.
***

Syspack is a system configuration management framework
covering the following scenarios and not limited to them:

- Tracking changes of configuration files on a Unix-like
  operating system such as /etc/hosts,

- Generation and deployment of system images with customized
  configuration files,

- Management of system instances running on bare-metal,
  in a jail environment or as a virtual machine backed by
  bhyve or qemu.

It uses spx(8) command line utility and BSD Make, and
runs on Unix-like operating systems, including *BSD, Linux,
Solaris and more.

## Installation

The spx(8) utility can be installed

% cd config/mk/spx && make install

## Create a template for your site

% mkdir s
% cd s
% spx init yoursitename

The "s" directory is the root for spx-managed files.  You can choose
a name.  The "yoursitename" parameter is typically an FQDN (e.g.,
example.com), but there is no specific restriction about the name, either.

"spx init" generates files and directories under "yoursitename."
You can find the "example" directory, and it corresponds to a single
host named "example."

See yoursitename/example/Makefile.inc and adjust TARGETHOST as the
real hostname, say "foo.example.com."  You can rename the "example" directory with
yoursitename/foo for simplicity even after invoking spx(8).
This means that "yoursitename/example" can be safely renamed to
"example.com/foo".

Files under example.com/foo are for the machine.  For example, in the
directory example.com/foo/etc means /etc on foo.example.com.
There is an example rc.conf in foo/etc directory, so
update it by removing it first and then invoking make fetch: 

% cd example.com/foo/etc
% rm rc.conf
% make fetch

The make fetch will copy /etc/rc.conf to example.com/foo/etc.

## Try it!

Modifying one or more configuration files, installing them, and testing them
are a typical cycle when you configure a system.  Let's add a comment line
to rc.conf.  Not in /etc but in example.com/foo/etc:

% cd example.com/foo/etc
% echo "# test" >> rc.conf

If you got a permission denied error, do "chmod +w rc.conf" in addition to it.

You can check what change is added by using "make diff":

% make diff

And "make status" lists what files are changed:

% make status

Syspack provides various make targets.  You can check what is available:

% make targets

and you can get more details for them:

% make targets-terse

## Configuration file editing cycle

For rc.conf in the previous section, you can install it to /etc/rc.conf:

% make install

The following is the typical editing cycle:

1. Edit files under foo/etc
2. Check the change using make diff
3. Install them into /etc using make install

However, /etc/rc.conf can be changed directly.  In that case, you can
use make reconcile to merge the change back to the local copy.
The modified workflow is as follows:

0. Invoke make status, and if you get "C" lines, you have some differences.
   Check the diff using make diff, and then "make reconcile" to merge.
1. Edit files under foo/etc
2. Check the change using make diff
3. Install them into /etc using make install

make reconcile invokes sdiff(1).

## More files

The files and their destination are defined in foo/etc/Makefile:

FILESDIR=	/etc
FILES=		rc.conf

If you want to manage /etc/hosts, you can simply add it like this:

FILESDIR=	/etc
FILES=		rc.conf hosts

or multiple lines are allowed with a backslash at the end of the line:

FILESDIR=	/etc
FILES=		rc.conf \
		hosts

make diff, install, and reconcile work for multiple files.  If you want to
limit the file handled by the make targets, you can use "make diff-rc.conf".
See the results of "make targets-terse".

## Permissions

There is a case you want to change the file permission and/or owner.
You can define them per-file basis using the following syntax:

FILES=		rc.conf
FILESMODE.rc.conf=	0644
FILESOWN.rc.conf=	root
FILESGRP.rc.conf=	wheel

If you define MODE, OWN, GRP without the filename, they will be applied
to all of the files:

FILES=		rc.conf hosts
FILESMODE=	0644
FILESOWN=	root
FILESGRP=	wheel

## Another destination directory

You can copy the foo/etc directory for another destination, say /etc/mail.
A recommended directory name is foo/etc.mail, and foo/etc.mail/Makefile
should look like this: 

FILESDIR=	/etc/mail
FILES=		aliases

.include <bsd.prog.mk>

When you add a new directory, update the following line in foo/Makefile:

SUBDIR=	etc \
	etc.mail

You can use status, diff, reconcile, and install at the example.com/foo directory.

## Service invocation

Files under /etc/mail are related to sendmail service.  So you usually need
to restart the daemon after editing them.  This operation can be integrated
by defining the following variables in foo/etc.mail/Makefile:

SERVICES=	sendmail

After adding it, you can see the following new targets in the results of
make targets:

 sendmail-start
 sendmail-stop
 sendmail-restart
 sendmail-reload
 sendmail-status
 sendmail-log

and "make status" now reports PIDs of sendmail daemons.

You can start sendmail daemons using "make sendmail-start".  You can also
do it using just "make start."  The latter will invoke all of the services
listed in SERVICES.

After invoking "make start," you should check the log files.  If the following
variable is defined, /var/log/maillog is automatically shown after
"make start":

LOGFILE.sendmail=	/var/log/maillog  

The log files are shown using tmux(1) or screen(1) if available.  If there is
none of them, tail(1) is used instead.  If you have the both on the system,
you can use PREFER_TMUX=yes or PREFER_SCREEN=yes environment variables
to control which is used.

## Further reading

Documentation is in progress.

[EOT]

