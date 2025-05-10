# git-coverage

Open test coverage uploaded to [`codecov`][codecov] in a web browser.

## Usage

The following command uses `git` details:

```sh
$ git coverage  # https://app.codecov.io/gh/zimeg/git-coverage
```

### Flags

Options are available for customization:

- `--help`: boolean. Print these usage details. Default: `false`

## Installation

Add a [build][releases] to `$PATH` for automatic detection:

```sh
$ mv ./path/to/git-coverage /usr/local/bin/
```

Read manual pages:

```sh
$ mv ./man/git-coverage.1 /usr/local/share/man/man1/
$ mandb
$ man git-coverage
```

## Details

This project is licensed under the MIT license and is not affiliated with or endorsed by Codecov.

[codecov]: https://about.codecov.io
[releases]: https://github.com/zimeg/git-coverage/releases/latest
