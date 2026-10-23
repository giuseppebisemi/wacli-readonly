# wacli-readonly

Read-only builds of [openclaw/wacli](https://github.com/openclaw/wacli) for an AI agent that must read WhatsApp but never write to it.

Upstream `--read-only` is a flag the caller can omit, and a running `sync --follow` executes sends delegated by other processes. This build removes both paths:

- `wacli auth` (pairing) and `wacli sync` are the only commands that can open WhatsApp for writing. Every other command runs read-only, whatever `--read-only` or `WACLI_READONLY` say. A read-only app refuses to connect to WhatsApp at all.
- `sync` starts no delegate server, so no other process can send, mark read, archive or change chats through it.

The whole change is [`patch/readonly.patch`](patch/readonly.patch), applied to an upstream release tag.

## Releases

A daily workflow checks the latest upstream release. For a new tag it applies the patch, builds a static `linux/amd64` binary with the Go image upstream pins, runs [`scripts/smoke.sh`](scripts/smoke.sh), and publishes `<tag>-ro`. If the patch no longer applies or the smoke test fails, no release is published and the workflow run fails.

When upstream release notes mention security, the workflow opens an issue.

A new release here does not update any machine. Installed binaries are updated by hand: back up the store first, as upstream advises.

## Verify a download

```sh
sha256sum -c SHA256SUMS
tar xzf wacli-linux-amd64.tar.gz
./wacli --version          # e.g. wacli 0.25.0-ro
./wacli send text --to 1 --message x   # read-only mode: command would intentionally modify WhatsApp ...
```

## License

wacli is MIT licensed, see [`LICENSE.upstream`](LICENSE.upstream). The patch and scripts here are under the same license.
