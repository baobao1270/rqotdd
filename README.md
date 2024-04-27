# rqotdd

rqotdd = Rust Quote Of The Day (QotD) Daemon

rqotdd is a simple implementation of [RFC 865](https://tools.ietf.org/html/rfc865) and a non-standard SSL/TLS version of it.

rqottd is written in Rust, and linked to MUSL: you can run it on any Linux distribution and macOS (Windows is not supported).

## Support Matrix
| Protocol | Default Port | Status    |
| -------- | ------------ | --------- |
| QotD TCP | 17           | ✅        |
| QotD UDP | 17           | ✅        |
| QotD SSL | 747          | ✅        |

| OS       | x86_64 | i686 | aaarch64 |
| -------- | ------ | ---- | -------- |
| Linux    | ✅     | ✅   | ✅       |
| macOS    | ✅     | ❌   | ✅       |

## Database File
rqotdd comes with a sample database file `database.txt`. **It does not comes with GitHub Release**. You can download it [here](https://github.com/baobao1270/rqotdd/blob/main/database.txt).

You can also use database from [fortune-mod](https://github.com/shlomif/fortune-mod/blob/master/fortune-mod/datfiles). To use it, add `--db-format "%"` to `rqotdd` argument command line.

## Build
 > TL; DR: Clone the git repository and run `make all`.

Before you start, there are some prerequisites you have to install on your system:
 - git
 - curl
 - make

A C/C++ Compiler is **NOT** required.

The program is written in Rust. You can setup Rust development environment by the following command:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Then, clone the git repository and build the program:
```bash
git clone https://github.com/baobao1270/rqotdd.git
cd rqotdd
make
```

The command will build the program for **CURRENT TARGET** and **link to GNU libc**.

### Cross Building
The program also support cross compilation and static linking with [MUSL](https://musl.cc/). However, **only Linux target is supported**. You can build the program with the following command:
```bash
make all
```

**Note: Don't run with `-j`. It may cause deadlocks.**

The command will build the program for target:

| Platform | Target   | Binary Path                       | Release Path                              |
| -------- | -------- | --------------------------------- | ----------------------------------------- |
| Linux    | x86_64   | `dist/linux-musl-x86_64/rqotdd`   | `dist/rqotdd-linux-musl-x86_64.tar.zst`   |
| Linux    | i686     | `dist/linux-musl-i686/rqotdd`     | `dist/rqotdd-linux-musl-i686.tar.zst`     |
| Linux    | aaarch64 | `dist/linux-musl-aaarch64/rqotdd` | `dist/rqotdd-linux-musl-aaarch64.tar.zst` |
| macOS    | x86_64   | `dist/darwin-x86_64/rqotdd`       | `dist/rqotdd-darwin-x86_64.tar.zst`       |
| macOS    | aaarch64 | `dist/darwin-aaarch64/rqotdd`     | `dist/rqotdd-darwin-aaarch64.tar.zst`     |

## License
The program is licensed under [Mozilla Public License 2.0](LICENSE).
