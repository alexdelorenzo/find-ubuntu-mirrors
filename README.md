# 🔍 Find Apt repository mirrors for Ubuntu
You can use `find-mirrors.sh` to find alternative repository mirrors for Ubuntu. It will check mirror lists and test the mirrors to see if they're working or not.

When it finds mirrors that are compatible with your preferences, [it will output the mirrors in Apt's `sources.list` format](#output).

The script also allows you to find Ubuntu mirrors for different architectures like:
 - ARM (`armhf` & `arm64`)
 - RISC-V (`riscv64`)
 - PPC (`ppc64el`)
 - IBM Z (`s390x`)

## Usage
```bash
$ export URL="https://gist.github.com/alexdelorenzo/8cdb21718c2d2d3f5f8beaad0bf6c843/raw"
$ curl -Ls "$URL" | bash
```

### Passing options
The script takes the following positional arguments or environment variables:

| Position | Variable name | Description | Default value |
| --|------|-------------|-------- |
| 1 | `$ARCH` | Architecture that the mirrors support | `amd64` |
| 2 | `$DISTRO` | Version of Ubuntu the mirrors support | `focal` |
| 3 | `$REPOSITORY` | The `apt` repository | `main` |
| 4 | `$PROTOCOL` | The `apt` repository protocol | `http` |
| 5 | `$JOBS` | Number of concurrent connections that the script makes | `4` |


Here's the syntax:
```bash
$ curl -Ls "$URL" | bash -s $ARCH $DISTRO $REPOSITORY $PROTOCOL $JOBS
```

If you want to find alternatives for `arm64` architectures while checking 6 repositories concurrently, you can do this:
```bash
$ curl -Ls "$URL" | bash -s arm64 focal main http 6
```

You can also use environment variables instead:
```bash
$ export ARCH=arm64 DISTRO=focal JOBS=6
$ curl -Ls "$URL" | bash
```

### Output
The script will output the mirrors it finds in Apt's `sources.list` format:
```bash
$ curl -Ls "$URL"
deb http://mirror.kumi.systems/ubuntu-ports/ focal main
deb-src http://mirror.kumi.systems/ubuntu-ports/ focal main

deb http://mirrors.portafixe.com/ubuntu/archive/ focal main
deb-src http://mirrors.portafixe.com/ubuntu/archive/ focal main
...
```

## Requirements
 - Bash
 - [GNU `parallel`](https://www.gnu.org/software/parallel/)
 - [`htmlq`](https://github.com/mgdm/htmlq)
 - [HTTPie](https://github.com/httpie/httpie)
