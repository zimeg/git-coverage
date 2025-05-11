# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][changelog], and this project adheres
to [Semantic Versioning][semver].

## [Unreleased]

### Maintenance

- Limit the permission set to the minimum required for all action workflow.
- Update dependencies of workflows whenever possible on repeated schedules.
- Write files about the project for maintenance and those exploring change.

## [0.2.0] - 2025-05-10

### Added

- Print usage details to standard output if a help flag is used in command.
- Document more detailed usage with manual pages for even better reference.
- Include installation instruction for moving a release download into path.
- Pick an upstream project according to the saved git remotes using a flag.
- Fetch the changes of a branch when showing coverage with a specific flag.
- Jump to a specific path in the browser if the flag contains these detail.

### Maintenance

- Confirm code formatting matches the standard expectations about language.
- Include legalese around licensing and unsponsored developments otherwise.

## [0.1.1] - 2025-05-03

### Maintenance

- Upload reports of test coverage to Codecov to complete proofs of concept.
- Save compilations for various machines to releases when tags are created.
- Include token permissions needed to create artifact content of a release.
- Check for changes to the changelog before allowing pull requests a merge.

## [0.1.0] - 2025-05-03

### Added

- Open coverage to a GitHub remote origin in a web browser with `coverage`.

<!-- a collection of links -->

[changelog]: https://keepachangelog.com/en/1.1.0/
[semver]: https://semver.org/spec/v2.0.0.html

<!-- a collection of releases -->

[Unreleased]: https://github.com/zimeg/git-coverage/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/zimeg/git-coverage/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/zimeg/git-coverage/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/zimeg/git-coverage/releases/tag/v0.1.0
