# ssm-connect

**Open a shell or port-forward to any EC2 instance — no SSH required.**

`ssm-connect` is a single-file Bash script that replaces `ssh` in environments where SSH has been removed from EC2 instances. It uses **AWS Systems Manager Session Manager** to open an interactive shell or a port-forwarding tunnel from a single command.

```
$ ssm-connect prod-api
✔ Connecting to prod-api (i-0abc123def456) as ubuntu

ubuntu@ip-10-0-1-42:~$
```

```
$ ssm-connect -L 5432:rds.internal:5432 bastion
✔ Forwarding localhost:5432 → rds.internal:5432 via bastion
ℹ Press Ctrl+C to stop
```

---

## Why?

| Feature | `ssh` | `ssm-connect` |
|---|---|---|
| Requires SSH (port 22) | ✅ | ❌ |
| Requires SSH key pair | ✅ | ❌ |
| Works in private subnets | ❌ | ✅ |
| Works through NAT/firewalls | ❌ | ✅ |
| Auditable (CloudTrail) | ❌ | ✅ |
| Session logging (S3/CloudWatch) | ❌ | ✅ |
| Instance lookup by name | ❌ | ✅ |
| Port forwarding | ❌ | ✅ |

---

## Requirements

**Required:**
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with credentials
- [`jq`](https://stedolan.github.io/jq/) (`apt install jq` / `brew install jq`)
- [AWS Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

**Optional:**
- [`fzf`](https://github.com/junegunn/fzf) — when installed, replaces the numbered list with a fuzzy interactive picker

**On EC2 instances:**
- SSM Agent installed and running
- IAM instance profile with `AmazonSSMManagedInstanceCore` (or equivalent)

---

## Installation

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/AlRos14/ssm-connect/main/install.sh | bash
```

### Manual

```bash
curl -fsSL https://raw.githubusercontent.com/AlRos14/ssm-connect/main/ssm-connect -o /usr/local/bin/ssm-connect
chmod +x /usr/local/bin/ssm-connect
```

### From source

```bash
git clone https://github.com/AlRos14/ssm-connect.git
sudo cp ssm-connect/ssm-connect /usr/local/bin/ssm-connect
```

---

## Usage

```
ssm-connect [options] [target]                   open an interactive shell
ssm-connect [options] -L local:remote_port       forward to port on instance
ssm-connect [options] -L local:host:remote_port  forward via instance to host:port
```

**Target** can be:
- nothing — interactive picker listing all running instances
- `i-0abc123...` — instance ID (exact match)
- `my-server` — Name tag (partial, case-insensitive)

**Options:**

| Flag | Description |
|---|---|
| `-p, --profile NAME` | AWS CLI profile |
| `-r, --region REGION` | AWS region |
| `-u, --user USER` | OS user on instance (default: `ubuntu`, env: `$SSM_USER`) |
| `-L, --forward SPEC` | Port-forward spec (see below) |
| `--reason TEXT` | Tag session with a reason (CloudTrail audit trail) |
| `-V, --version` | Print version and exit |
| `-h, --help` | Print help and exit |

---

## Examples

```bash
# Interactive picker — lists all running instances
ssm-connect

# Connect by name tag (partial, case-insensitive)
ssm-connect prod-api

# Connect using a specific AWS profile and region
ssm-connect -p prod-account -r eu-west-1 web

# Connect as a different OS user
ssm-connect -u ec2-user my-server
# or: SSM_USER=ec2-user ssm-connect my-server

# Connect by instance ID
ssm-connect i-052c8baf8bbe98f2f

# Tag the session with a reason (appears in CloudTrail)
ssm-connect --reason "incident-2026-03" prod-api

# Forward local port 5432 to port 5432 on the instance
ssm-connect -L 5432:5432 db-server

# Tunnel to a private RDS endpoint via a bastion instance
ssm-connect -L 5432:mydb.cluster-xxxx.eu-west-1.rds.amazonaws.com:5432 bastion

# Forward local 8080 to an internal service via a bastion
ssm-connect -L 8080:internal-service.local:80 bastion
```

---

## Port forwarding

Port forwarding runs in the foreground. Press **Ctrl+C** to stop.

### Forward to a port on the instance itself

```bash
ssm-connect -L <local_port>:<remote_port> <instance>
```

Uses `AWS-StartPortForwardingSession`. Useful for accessing services running directly on the EC2 instance (e.g., a local database, a web server on port 8080).

### Forward via the instance to a remote host

```bash
ssm-connect -L <local_port>:<remote_host>:<remote_port> <instance>
```

Uses `AWS-StartPortForwardingSessionToRemoteHost`. Useful for accessing private resources the instance can reach but you cannot — such as RDS, ElastiCache, or internal microservices.

```
Your machine   ──── HTTPS ────▶   EC2 instance   ──── private VPC ────▶   RDS / Redis / …
localhost:5432                     (bastion)                               rds.internal:5432
```

---

## How it works

### Shell session

1. Resolves the target instance (by ID, Name tag, or interactive picker)
2. Runs `aws ssm start-session` using the `AWS-StartInteractiveCommand` document
3. Spawns a login shell as the configured OS user
4. The session runs entirely over HTTPS through the SSM endpoint — no inbound ports needed

### Port forwarding

Same resolution step, then calls `aws ssm start-session` with the appropriate forwarding document (`AWS-StartPortForwardingSession` or `AWS-StartPortForwardingSessionToRemoteHost`) and runs in the foreground until interrupted.

---

## IAM reference

### Local user IAM policy

Your AWS IAM user needs:

- `ec2:DescribeInstances` — resolve instance names to IDs
- `ssm:StartSession` — open shell or port-forwarding sessions
- `ssm:TerminateSession` — close sessions cleanly

See [`iam/policy-user.json`](iam/policy-user.json) for a complete policy definition.

### EC2 instance requirements

Instances need an IAM instance profile that allows the SSM Agent to register with Systems Manager. The AWS-managed `AmazonSSMManagedInstanceCore` policy covers this.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

---

## License

[MIT](LICENSE) © Alejandro Rosado
