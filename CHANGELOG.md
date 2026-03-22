# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-03-22

### Added
- Initial release
- Interactive instance picker when no argument is provided
- Direct connect by instance ID (`i-0abc123...`)
- Direct connect by Name tag (partial, case-insensitive match)
- Multiple-match disambiguation with numbered selection prompt
- Configurable OS user via `SSM_USER` environment variable (default: `ubuntu`)
- Coloured output (errors, info, success)
- Dependency checks for `aws` and `jq`
