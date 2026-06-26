# koha-testing-docker (a.k.a. _KTD_)

This project provides a dockered solution for running a Koha ILS development 
environment inside Docker containers.

It is built using the package install with the needed tweaks (including koha-gitify)
in order to create such environment.

## Requirements

### Software

This project is self contained and all you need is:

- A text editor to tweak configuration files
- Docker ([install instructions](https://docs.docker.com/engine/install/#server))
- Docker Compose v2 ([install instructions](https://docs.docker.com/compose/install/linux/#install-using-the-repository))
  - You need to have docker compose 2.33.1 or later, `docker compose version` will tell you what you have if you already have it installed through your distribution.

Notes:
* **Linux** users, only Docker engine (aka Docker server) is required to run `ktd`.
* **Windows** users are recommended to first [install Debian on WSL](https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux#WSL_2_with_systemd_support) and can then [install Docker directly in Debian](https://docs.docker.com/engine/install/debian/).
* alternatively, **Windows** users may also use [Docker Desktop](https://docs.docker.com/compose/install/compose-desktop/) on Windows and then [install Debian on WSL](https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux#WSL_2_with_systemd_support). However, Docker Desktop will then need to be started in Windows before ktd can be used in WSL.
* **macOS** users use [Docker Desktop](https://docs.docker.com/compose/install/compose-desktop/) which already ships Docker Compose v2.

### Hardware

- A generic x86_64 system or arm64v8 system (Apple M1/M2, AWS EC2 Graviton)
- At least 2.6 GiB of free RAM (not counting web browser)
- If you want to try Elastic, count at least 2 GiB more of free RAM.

## Setup

It is not a bad idea to organize your projects on a directory. For the purpose
of simplifying the instructions we will pick `~/git` as the place in which to
put all the repository clones:

```shell
mkdir -p ~/git
export PROJECTS_DIR=~/git
```

* Clone the `koha-testing-docker` project:

```shell
cd $PROJECTS_DIR
git clone https://gitlab.com/koha-community/koha-testing-docker.git koha-testing-docker
```

* Clone the `koha` project (skip and adjust the paths if you already have it):

```shell
cd $PROJECTS_DIR
git clone --branch main --single-branch --depth 1 https://git.koha-community.org/Koha-community/Koha.git koha
```

**Note:** this will do a shallow clone only fetching the latest commit of the main branch to speed up the process. Alternatively, you could do a full clone with

```shell
git clone https://git.koha-community.org/Koha-community/Koha.git koha
# be patient, it's a >1.4GiB download (2023-05)
```

* Set some **mandatory** environment variables:

For bash users:
```shell
echo "export PROJECTS_DIR=$PROJECTS_DIR" >> ~/.bashrc
echo 'export SYNC_REPO=$PROJECTS_DIR/koha' >> ~/.bashrc
echo 'export KTD_HOME=$PROJECTS_DIR/koha-testing-docker' >> ~/.bashrc
echo 'export PATH=$PATH:$KTD_HOME/bin' >> ~/.bashrc
echo 'export LOCAL_USER_ID=$(id -u)' >> ~/.bashrc
```

For zsh users:
```shell
echo "export PROJECTS_DIR=$PROJECTS_DIR" >> ~/.zshenv
echo 'export SYNC_REPO=$PROJECTS_DIR/koha' >> ~/.zshenv
echo 'export KTD_HOME=$PROJECTS_DIR/koha-testing-docker' >> ~/.zshenv
echo 'export PATH=$PATH:$KTD_HOME/bin' >> ~/.zshenv
echo 'export LOCAL_USER_ID=$(id -u)' >> ~/.zshenv
```

For this to take effect on your current terminal, run:

For bash:
```shell
source ~/.bashrc
```

For zsh:
```shell
source ~/.zshenv
```

* Generate your personal _.env_ file:

```shell
cd $PROJECTS_DIR/koha-testing-docker
cp env/defaults.env .env
```

* Add your user to the docker group

```shell
sudo usermod -aG docker ${USER}
```

Then reboot or restart your session.

## Updating

From time to time (and especially when your local setup does not work anymore) you have to pull new `ktd` containers and/or pull new changes from Koha itself:

```shell
# update Koha
cd $PROJECTS_DIR/koha
git pull

# update koha-testing docker source
cd $PROJECTS_DIR/koha-testing-docker
git pull

# update containers
ktd pull

# remove node_modules
ktd --shell
rm -rf node_modules

# restart / reset
restart_all # or reset_all, which will nuke all data
```

## Basic usage

In order to launch _KTD_, you can use the `ktd` wrapper command. It is a wrapper around the
`docker compose` command so it accepts its parameters:

* Starting:
  ```shell
   ktd up
   ```
* Get into the Koha container shell (instance user)
  ```shell
  ktd --shell
  ```
* Get into the Koha container shell (root user)
  ```shell
  ktd --root --shell
  ```
* Run a command inside the container
  ```shell
  ktd --shell --run 'echo hola'
  ```
* Get into a DB (mysql) shell
  ```shell
  ktd --dbshell
  ```
* Watching the _koha_ container logs
  ```shell
  ktd --logs
  ```
* Updating the used images:
  ```shell
  ktd pull
  ```
* Shutting it down
  ```shell
  ktd down
  ```
* Waiting for startup completion
  ```shell
  ktd --wait-ready 100 && echo "YAY" || echo "BOO"
  ```
* Adding services to our stack\
  Several option switches are provided for more fine-grained control:
  ```shell
  ktd --es7 up
  ktd --selenium --os1 --plugins --sso up
  ktd --mana up
  ```

Note: the `pull` command would also work if you add several option switches. So running:

```shell
ktd --es7 pull
```

will also download/update the Elasticsearch 7.x image to be used.

For a complete list of the option switches, run the command with the _--help_ option:

```shell
ktd --help
```
### Getting to the web interface after `ktd up`
Once you have run `ktd up` and it has finished, you can access the Koha web interface.

You may also consider if proxied `KTD`, described further below, is something you want.

1. Figure out the IP address it's running as
   ```sh
   $ ktd --shell
   kohadev-koha@kohadevbox:koha(main)$ ip a
   ...
   2: eth0@if7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 62:24:ad:a1:18:2b brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.18.0.4/16 brd 172.18.255.255 scope global eth0
       valid_lft forever preferred_lft forever
   ```
   In this example, the IP address is `172.18.0.4`
2. Point your web browser to these URLs, changing the IP address as needed:
   * http://172.18.0.4:8080/ for the OPAC
   * http://172.18.0.4:8081/ for the staff interface

## Proxied `KTD`

`KTD` ships a configuration for launching a local proxy which has two benefits:

* Allows running all services on port 80
* Allows running several `KTD` instances in parallel

### Start the proxy

Before launching `ktd` in proxied mode, you need to start the proxy itself. We include
a `ktd_proxy` command for convenience:

```shell
ktd_proxy --start
ktd_proxy --status
ktd_proxy --stop
```

The proxy status dashboard can be accessed by pointing you browser to [http://proxy.localhost](http://proxy.localhost).

### Start proxied `KTD`

If `KTD` is going to run behind the shipped proxy, you will need to add the `--proxy` flag
on your usual command. For example:

```shell
ktd --proxy --es7 --plugins up -d
```

The default `KTD` instance name is **kohadev** to match the previous behavior. As such, you will be able
to access this instance using the following URLs:

* OPAC: http://kohadev.localhost
* Staff interface: http://kohadev-intra.localhost

### Running another instance in parallel

Another parameter has been added to the `ktd` script, `--name`. This will allow us to specify a different
namespace for a new `KTD` instance. For example:

```shell
ktd --proxy --name kohadev2 up -d
```

Conveniently, this instance will be accessed by using the following URLs:

* OPAC: http://kohadev2.localhost
* Staff interface: http://kohadev2-intra.localhost

All usual `ktd` options are still available, but you need to make sure you specify the `--name` parameter
correctly. For example:

```shell
ktd --name kohadev2 --logs
ktd --name kohadev2 --shell
```

### Flexibility

On the previous example, we launched a new `KTD` by using a different name. But you should note that any
parameters that are available for launching `KTD` can be passed to this new instance.

This implies you could launch another codebase, Docker image, DB engine, and so on.

Examples:

```shell
SYNC_REPO=/path/to/23.11/code ktd --proxy --name 2311 up -d
DB_IMAGE=mysql:8.0 ktd --proxy --name mysql8 up -d
```

We highly recommend the use of [git worktrees](https://git-scm.com/docs/git-worktree) for having different
codebases on your hard drive without filling it up quickly.

### Custom File Sourcing and Commands at run time

With the ` --localrun` flag, you can add custom file sources into your runfile so each instance of your shell has any custom alias or other files sourced. 

On your computer under the `koha-testing-docker/files` folder, open `run.sh`

Before `touch /ktd_ready` you can add commands. 
Examples:
```bash
echo 'source /kohadevbox/koha/shared/.custom_bash_commands.sh' >> /var/lib/koha/kohadev/.bashrc
echo 'newktd' >> /var/lib/koha/kohadev/.bashrc
```

The above options add the lines to the kohadev user `.bashrc` file and will run the custom command `newktd` which is defined in `/kohadevbox/koha/shared/.custom_bash_commands.sh`

In the example above, the `newktd` function runs the following commands:

```bash
    eval "$(ssh-agent -s)" #turn on ssh
    ssh-add /kohadevbox/koha/shared/gitssh_id #add your ssh
    source /kohadevbox/koha/shared/.bash_aliases #source your aliases
    sudo /etc/cron.daily/plocate #build the database for use with the locate command
    source /kohadevbox/koha/shared/.git-completion.bash #source a custom completion file for use with some custom functions
    source /kohadevbox/koha/shared/.bashrc #source the custom bashrc, which allows for keeping a shared history between instances
```
Examples of the files used can be found in [this repository](https://github.com/lisettebws/shared).
## Available commands and aliases

The container comes with some helpful aliases to improve productivity, many of which are available 
from both the kohadev and root users.

In most cases you will want to access the container as the kohadev user using:

```shell
ktd --shell
```

Whilst logged in as this user, the following commands are available

### **kohadev only**
| Command            | Function                                                                                    |
|--------------------|---------------------------------------------------------------------------------------------|
| **qa**             | Run the QA scripts on the current branch. For example: *qa -c 2 -v 2*                       |
| **prove_debug**    | Run the *prove* command with all parameters needed for starting a remote debugging session. |

### **kohadev and root**
| Command               | Function                                                                    |
|-----------------------|-----------------------------------------------------------------------------|
| **koha-intra-err**    | tail the intranet error log                                                 |
| **koha-opac-err**     | tail the OPAC error log                                                     |
| **koha-plack-log**    | tail the Plack access log                                                   |
| **koha-plack-err**    | tail de Plack error log                                                     |
| **koha-user**         | get the db/admin username from koha-conf.xml                                |
| **koha-pass**         | get the db/admin password from koha-conf.xml                                |
| **dbic**              | recreate the schema files using a fresh DB. Accepts the *--force* parameter |
| **flush_memcached**   | flush all key/value stored on memcached                                     |
| **restart_all**       | restarts memcached, apache and plack                                        |
| **reset_all**         | drop and recreate the koha database [*]                                     |
| **reset_all_marc21**  | same as **reset_all**, but forcing MARC21                                   |               
| **reset_all_unimarc** | same as **reset_all**, but forcing UNIMARC                                  |
| **start_plack_debug** | start Plack in debug mode, trying to connect to a remote debugger if set.   |
| **updatedatabase**    | run the updatedatabase.pl script in the right context (instance user)       |

Note: it is recommended to run __start_plack_debug__ on a separate terminal
because it doesn't free the prompt until the process is stopped.

[*] **reset_all** actually:
* Drops the instance's database, and creates an empty one.
* Calls the misc4dev/do_all_you_can_do.pl script.
* Populates the DB with the sample data, using the configured MARC flavour.
* Create a superlibrarian user.
* Updates the debian files in the VM (overwrites the ones shipped by the koha-common package).
* Updates the plack configuration file for the instance.
* Calls **restart_all**

### **root only**
| Command            | Function                                                                                    |
|--------------------|---------------------------------------------------------------------------------------------|
| **kshell**:        | get into the instance user, on the kohaclone dir                                            |

## Running the right branch

By default the _KTD_ that will start up is configured to work for the main branch of Koha.  If you want to run an image
to test code against another koha branch you should use the `KOHA_IMAGE` environment variable before starting the image 
as above.

```shell
KOHA_IMAGE=23.11 ktd up
```

Please note that you can only use branches defined
[here](https://hub.docker.com/r/koha/koha-testing/tags). If you want to work on
a local feature branch in Koha, make sure that `SYNC_REPO` points to the
correct directory on your machine, and that you are in the correct branch
there. Please also note that the Koha sources are installed to
`/kohadevbox/koha` (via `koha-gitify`) and not `/usr/share/koha`!

## Choosing a MARC flavour

The default behaviour when you launch _KTD_ is to start up a Koha instance
configured for the MARC21 flavour. If you wish to work on a UNIMARC-capable
Koha instance, you can do so by setting the `KOHA_MARC_FLAVOUR` environment
variable before starting the container with `ktd`:

```shell
KOHA_MARC_FLAVOUR=unimarc ktd up
```

You can even launch two Koha containers in parallel using Proxied `KTD`, one
for each MARC flavour (for example, when you want to follow a Test plan from
a Bug that involves testing both MARC21 and UNIMARC):

```shell
ktd_proxy --start
KOHA_MARC_FLAVOUR=marc21 ktd --proxy --name marc21 up
KOHA_MARC_FLAVOUR=unimarc ktd --proxy --name unimarc up
```

## Advanced usage

### Docker parameters

With some exceptions (when using `--shell` or `--logs`) the `ktd` script is mostly a wrapper for
the `docker compose` tool. So all trailing options after the shipped option switches will be passed
to the underlying `docker compose` command.

For example, if you want to run _KTD_ in daemon mode, so it doesn't take over the terminal or die
if you close it, you can run it like this:

```shell
ktd <options> up -d
```

where `<options>` are the valid `ktd` option switches. If your usage requires more options you should
check `docker compose --help` or refer to the [Docker compose documentation](https://docs.docker.com/compose/).

### Building locally

If you want to test changes to one of the Docker images, `ktd` offers a `--build` parameter that can be
passed so it builds the required image and uses, instead of pulling it from the Docker registry. It can be
used like this:

```shell
KOHA_IMAGE_OS=arm64v8/bookworm ktd --proxy --name test_arm --build up
KOHA_IMAGE_OS=noble ktd --proxy --name test_noble --build up
```

Building the images, manually, can be straight-forward by reading the `.gitlab-ci` file. We ship different
`Dockerfiles` that can just be built in traditional ways.

### Developing plugins using ktd

_KTD_ ships with some nice tools for working with plugins

Please see the [wiki](https://gitlab.com/koha-community/koha-testing-docker/-/wikis/Developing-plugins) for details

### Testing emails with fake SMTP server
You can use `--smtp` option to start a [Mailpit](https://mailpit.axllent.org/) instance for testing emails.

```shell
ktd --smtp up
```

**SMTP Configuration:**
In _Administration > SMTP Servers_: Create a new SMTP server with the following configuration:

- Host: `smtp`
- Port: `1025`
- Default server: `yes`

You can access the Mailpit web interface at `http://localhost:8025` or `http://smtp.<instance>.localhost` (using `--proxy` option), to view the trapped emails sent by Koha. This is also very useful for testing email headers, subject, templates, links, etc.

### Keycloak / SSO
ktd ships with a keycloak option so one may use it for testing and developing single sign on functionality.

Please see the [wiki](https://gitlab.com/koha-community/koha-testing-docker/-/wikis/Using-Keycloak/) for details

### Hot-reload Plack / automatic reload after code changes

Adding hot-reload to `koha-plack` is not feasible. Here is a slightly hackish way to enable it anyway:

1. Start ktd
2. In a second terminal, start a second shell: `ktd --shell`
3. In that shell, first stop plack: `koha-plack --stop kohadev`
4. Then start Koha directly via `plackup`:

```
DEV_INSTALL=1 KOHA_HOME=/kohadevbox/koha \
  /usr/bin/plackup -M FindBin --workers 2 --user=kohadev-koha --group=kohadev-koha  -E deployment --socket /var/run/koha/kohadev/plack.sock -s Starman \
  -R /kohadevbox/koha \
  /etc/koha/plack.psgi
```

Using `-R /kohadevbox/koha` makes `plackup` watch everything in `/kohadevbox/koha` and will restart Plack on changes to any file in that directory. Depending on what you are doing, it make more sense to use eg `-R /kohadevbox/koha/Koha -R /kohadevbox/koha/C4`.

You can also add `DEV_INSTALL` and `KOHA_HOME` to your `.env` file so you don't have to specify them here.

### Debugging with VSCode

KTD ships with built-in support for Perl debugging using VSCode and the DAP protocol.
Set breakpoints, step through code, and inspect variables - both for tests and Plack
(web requests through the browser).

See [DEBUGGING.md](DEBUGGING.md) for the full setup guide.

### Using ktd to test and developp Mana

You have to have a mana instance running first, using the `mana up` command (you may have to run it twice) from [the mana repo](https://gitlab.com/koha-community/koha-mana).

Next, you can run
```sh
ktd --mana up
```

This will allow koha to connect to the network created by mana, and mana will be usable right away.

## Translation files

Translation files (.po files) have been removed from [the docker container](https://gitlab.com/koha-community/koha-testing-docker/-/issues/386) and [the Koha codebase](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=35174).

When _KTD_ container starts up, it will deal with the .po files if needed, depending on the state of `misc/translator/po` and the value of `SKIP_L10N` (defaults to `no`).

 1. If `SKIP_L10N=yes`, nothing is done. No translations are installed, which saves a lot of bandwidth and file storage.
 1. If `misc/translator/po` is empty, [koha-l10n](https://gitlab.com/koha-community/koha-l10n) will be cloned
 2. If `misc/translator/po` exists and is a git repository, koha-l10n will be pulled and the corresponding branch will be checked out (if there are no local changes!)
 3. If `misc/translator/po` exists and is not a git repository, nothing is done (we are on a branch prior to the removal)

Note that _KTD_ will not automatically remove changes that have been made to the .po files.

### Installing translations

Use `koha-translate` with the option `--dev kohadev`.

```shell
# in a koha-shell
koha-translate --install de-DE --dev kohadev
```

### Update the files

This will only work if `misc/translator/po` actually is a checkout of koha-l10n.

#### Fetch new translations

To manually fetch new translations from koha-l10n (and so Weblate) you can fetch the git repository.

For main:

```shell
# in a koha-shell
cd misc/translator/po
git fetch origin
git reset --hard origin/main
```

#### With new strings

If you want to update the .po files with new strings you have in your Koha codebase (when testing a patch for instance):

```shell
# in a koha-shell
gulp po:update --lang $LANG
```

To generate new templates using those new .po files

```shell
# in a root shell
koha-translate --update $LANG --dev kohadev
```

(Yes, this is confusing)

### Common problems

#### Detached HEAD

If you get 'You are not currently on a branch' it means that you are not on a branch. This has been by a previous bug in ktd. You should pull a newest koha-testing-docker docker image 

#### Incorrect permissions

If misc/translator/po does not have the correct permissions (not owned by kohadev-koha), the gulp command will fail with something similar to

```
msgmerge: cannot create output file "misc/translator/po/es-ES-pref.po": Permission denied
```

You need to adjust the permissions with

```shell
chown -R kohadev-koha:kohadev-koha misc/translator/po
```

#### Error: ENOENT: no such file or directory, open '/tmp/.../Koha-xxx.pot'

koha-l10n is not up-to-date. You can update with with:

```shell
cd misc/translator/po
git fetch origin
git reset --hard origin/main
```

#### Error: ENOENT: no such file or directory, stat '[...]how-to.pl'

See Koha [bug 34915](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=34915) and [issue #401](https://gitlab.com/koha-community/koha-testing-docker/-/issues/401).

### Another problem?

If you are getting another problem you should locate the "Fetching koha-l10n" line in ktd startup and see if you have an error right after.
This is the kind of output you will have when ktd starts up after a gulp po:update session
```
koha-koha-1       | Install Koha-how-to
koha-koha-1       | Fetching koha-l10n
koha-koha-1       | From https://gitlab.com/koha-community/koha-l10n
koha-koha-1       |    37ed79d3..c4cc4e86  main        -> origin/main
koha-koha-1       |    23095e8c..0470ed29  21.11       -> origin/21.11
koha-koha-1       |    23aab8b2..154a1a8c  22.05       -> origin/22.05
koha-koha-1       |    7b797c63..8d4a7671  22.11       -> origin/22.11
koha-koha-1       |    7fe82983..e80f8014  23.05       -> origin/23.05
koha-koha-1       |    0f739e99..fbcab13e  terminology -> origin/terminology
koha-koha-1       | error: Your local changes to the following files would be overwritten by checkout:
koha-koha-1       |     es-ES-staff-prog.po
koha-koha-1       | Please commit your changes or stash them before you switch branches.
koha-koha-1       | Aborting
koha-koha-1       | Chowning po files
```

## Problems?

### If you see the following error on 'ku' after initial setup, try a reboot

```
ERROR: Couldn't connect to Docker daemon at http+docker://localhost - is it running?
```

### If starting fails with "database not empty", try running `ktd down` or `kd`

It's likely that last start of _KTD_ failed and needs cleanup. Or that it was shutdown without `ktd down` or `kd` that are necessary for a clean shutdown.

# Documentation

For more advanced options and more detailed explanations of how this project works please see the [wiki](https://gitlab.com/koha-community/koha-testing-docker/-/wikis/Koha-Testing-Docker)
