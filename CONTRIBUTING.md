# Contributing to ssm-connect

Thank you for considering a contribution! This is a small, focused tool — contributions that keep it simple and dependency-free are most welcome.

---

## Getting started

1. **Fork** the repository on GitHub
2. **Clone** your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/ssm-connect.git
   cd ssm-connect
   ```
3. **Create a branch** for your change:
   ```bash
   git checkout -b feat/my-improvement
   ```
4. **Make your changes**, then test them
5. **Commit** following the [commit message convention](#commit-messages)
6. **Open a pull request** against `main`

---

## What makes a good contribution

- **Bug fixes** — especially edge cases in instance resolution or session handling
- **Portability improvements** — making the script work reliably on macOS and more Linux distributions
- **Cleaner UX** — better error messages, clearer output
- **Documentation** — corrections, examples, clearer explanations

Please keep the script as a single self-contained Bash file with no added runtime dependencies beyond `aws` and `jq`.

---

## Commit messages

Use the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>: <short description>
```

Common types:

| Type | When to use |
|---|---|
| `feat` | New behaviour or option |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change with no behaviour change |
| `chore` | Tooling, CI, dependencies |

---

## Testing

The test suite covers input validation functions and CLI behaviour (flags, exit codes, error messages). No AWS credentials or network access are required.

```bash
bash tests/test_validation.sh   # unit tests for validate_user / validate_port / validate_host
bash tests/test_cli.sh          # CLI integration tests using a mock aws command
```

Both scripts exit 0 on success and print a `Results: N passed, 0 failed` summary.

**How the tests work**

- `test_validation.sh` sources the script with `_SSMC_SOURCE_ONLY=1`, which loads all function definitions without executing the main logic. Functions are then called directly in subshells.
- `test_cli.sh` runs the script as a black box with a mock `aws` binary injected at the front of `$PATH`. The mock returns minimal valid responses so the script can reach the code paths under test without touching AWS.

Before opening a PR, please verify that both test files pass cleanly.

---

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
