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

There is no automated test suite. Before opening a PR, please manually verify:

- `ssm-connect` with no arguments (interactive mode)
- `ssm-connect <name>` — single match, multiple matches, no match
- `ssm-connect <instance-id>` — valid ID, invalid ID
- `SSM_USER=ec2-user ssm-connect <name>`

---

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
