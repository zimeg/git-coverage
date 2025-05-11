# Maintainers guide

Top 'o this these tolerable times to the tested tester testing tests.

**Outline**:

- [Project setup](#project-setup)
- [Testing](#testing)
- [Merging pull requests](#merging-pull-requests)
- [Cutting a release](#cutting-a-release)

## Project setup

Building from source to reflect any code changes only takes a few fast steps.

1. Install the latest version of [Zig][ziglang].
2. From a path for development, download the source and compile `git-coverage`:

```sh
$ git clone https://github.com/zimeg/git-coverage.git
$ cd git-coverage
$ zig build
```

An [understanding of Zig][learn_zig] is a common prerequisite for programming
within this project and is a good language to learn!

### Nix configuration

A prepared development environment can be guaranteed from the `flake.nix`:

```sh
$ nix develop
```

Using [Nix][nix] is completely optional but somewhat recommended for
consistency.

### Project structure

This project hopes to use different directories to separate various concerns,
currently using the following structure:

- `/` – primary project files and metadata for the repository
- `.github/` – information for collaboration and continuous integrations
- `man/` – documentation pages with the most descriptive detail
- `src/` – files that contain logic adjacent to some matching tests

### Build commands

For ease of remembering, some commands are noted as follows:

- `zig build` – compile the program compilations
- `zig fmt src/**/*.zig` – format the code
- `zig test src/main.zig` – run unit tests

The output of compilations can be found as `zig-out/bin/git-coverage`.

## Testing

All tests should aim to cover the common cases with expected behaviors to build
confidence in changes.

### Unit tests

Written tests should reside within the source code and adjacent to the various
functionalities being tested.

All tests can be run with `zig test src/**/*.zig` and example test cases can be
found throughout this project.

While coverage isn't critical, various permutations of input are often used to
check edge cases. There's some balance.

### Integration tests

Assurance that the program works as expected with an actual `git` project should
be confirmed with commands changed:

```sh
$ zig build
$ ./zig-out/bin/git-coverage
```

Confirming that flag options are tested remains an exercise for the maintainer.

### On the remote

When changes are proposed or made to the remote repository, the full test suite
is performed to verify stability in any changes.

Additionally, some change to the `CHANGELOG.md` is checked for on pull requests.

## Merging pull requests

Confidence in the tests should cover edge cases well enough to trust the suite.
A green status signals nothing broke as a result of changes, and an example run
can be seen in the actions output.

On any change, the following should be verified before merging:

- Documentation is correct and updated everywhere necessary
- Code changes move the project in a positive direction

If that all looks good and the change is solid, the **Squash and merge** awaits.

## Cutting a release

When the time is right to bump versions, either for new features or bug fixes,
the following steps can be taken:

1. Add the new version header to the `CHANGELOG.md` to mark the release
2. Preemptively update the version links at the end of the `CHANGELOG.md`
3. Bump the version and date of the next release for manual `man/git-coverage.1`
4. Commit these changes to a branch called by the version name – e.g. `v1.2.3`
5. Open then merge a pull request with these changes
6. Draft a [new release][releases] using the version name and entries from the
   `CHANGELOG.md`
7. Publish this as the latest release!
8. Close the current milestone for the latest release then create a new one

In deciding a version number, best judgement should be used to follow
[semantic versioning][semver].

[learn_zig]: https://pedropark99.github.io/zig-book/
[nix]: https://zero-to-nix.com
[releases]: https://github.com/zimeg/git-coverage/releases
[semver]: https://semver.org/spec/v2.0.0.html
[ziglang]: https://ziglang.org/learn/getting-started/
