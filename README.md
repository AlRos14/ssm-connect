# ssm-connect

**Open a shell on any EC2 instance — no SSH required.**

`ssm-connect` is a single-file Bash script that replaces `ssh` in environments where SSH has been removed from EC2 instances. It uses **AWS Systems Manager Session Manager** to open an interactive shell from a single command.

```
$ ssm-connect my-server
✔ Connecting to my-server (i-0abc123def456) as ubuntu

ubuntu@ip-10-0-1-42:~$
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

---

## Requirements

- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with credentials
- [`jq`](https://stedolan.github.io/jq/) (`apt install jq` / `brew install jq`)
- [AWS Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
- EC2 instances must have the **SSM Agent** installed and running, with an IAM role that includes `ssm:StartSession` permissions

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

```bash
ssm-connect                   # interactive: list running instances and pick one
ssm-connect <name>            # connect by Name tag (partial, case-insensitive)
ssm-connect <instance-id>     # connect by instance ID
```

Override the default OS user (`ubuntu`) with:

```bash
SSM_USER=ec2-user ssm-connect my-server
```

### Examples

```bash
# Interactive mode — shows all running instances
ssm-connect

# Connect by name tag (partial match)
ssm-connect prod-api

# Connect by instance ID
ssm-connect i-052c8baf8bbe98f2f

# Connect as a different user
SSM_USER=ec2-user ssm-connect my-server
```

### Interactive mode

When multiple instances match the provided name, or when no argument is given, `ssm-connect` displays a numbered table and prompts for a selection:

```
  #    Instance ID            Private IP       Public IP        Name
  ---- ---------------------- ---------------- ---------------- ----
  1    i-0abc123def456789a    10.0.1.10        -                prod-api
  2    i-0def456abc123789b    10.0.2.20        -                prod-worker

Select instance [1-2]: _
```

---

## How it works

1. Resolves the target instance (by ID, Name tag, or interactive list)
2. Runs `aws ssm start-session` using the `AWS-StartInteractiveCommand` document
3. Spawns a login shell as the configured OS user (`sudo -i -u <user>`)
4. The session runs entirely over HTTPS through the SSM endpoint — no inbound ports needed

---

## IAM reference

### Local user IAM policy

Your AWS IAM user needs the following permissions:

- `ec2:DescribeInstances` — resolve instance names to IDs
- `ssm:StartSession` — open an interactive shell session
- `ssm:TerminateSession` — close sessions cleanly

See [`iam/policy-user.json`](iam/policy-user.json) for a complete policy definition.

### EC2 instance requirements

Instances need an IAM instance profile with an `ssm:StartSession` permission (the AWS-managed `AmazonSSMManagedInstanceCore` policy covers this).

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

---

## License

[MIT](LICENSE) © Alejandro Rosado
