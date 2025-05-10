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

Add a build to `$PATH` for automatic detection.

Read manual pages:

```sh
$ cp ./man/git-coverage.1 /usr/local/share/man/man1/
$ mandb
$ man git-coverage
```

[codecov]: https://about.codecov.io
