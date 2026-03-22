# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.1] - 2026-03-22

### Added
- Port forwarding via `-L local:remote_port` (forward to instance port) and `-L local:host:remote_port` (tunnel via instance to remote host)
- `--profile` / `-p` flag to specify an AWS CLI profile per invocation
- `--region` / `-r` flag to specify an AWS region per invocation
- `--user` / `-u` flag as an alternative to the `$SSM_USER` environment variable
- `--reason` flag to attach a reason string to the SSM session (visible in CloudTrail)
- `--help` / `-h` flag with full usage output
- `--version` / `-V` flag
- `fzf` support in interactive mode — when `fzf` is installed, the numbered list is replaced with a fuzzy picker (falls back gracefully when not available)
- `warn()` helper for yellow warning messages

### Changed
- All UI output (colours, tables, prompts) now goes to stderr, keeping stdout clean
- Refactored instance resolution into focused functions: `resolve_by_id`, `resolve_by_name`, `resolve_interactive`
- `aws` calls are now routed through `aws_cmd()` which injects `--profile` / `--region` when set

### Fixed
- `run-parts /etc/update-motd.d/` is now guarded with `command -v run-parts` to avoid failures on non-Ubuntu distributions (Amazon Linux, RHEL, etc.)

---

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Interactive instance picker when no argument is provided
- Direct connect by instance ID (`i-0abc123...`)
- Direct connect by Name tag (partial, case-insensitive match)
- Multiple-match disambiguation with numbered selection prompt
- Configurable OS user via `SSM_USER` environment variable (default: `ubuntu`)
- Coloured output (errors, info, success)
- Dependency checks for `aws` and `jq`
