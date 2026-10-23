# Two Hours One Life Server — GitHub Codespaces setup

This fork adds a straightforward Codespaces workflow for building and running a **Two Hours One Life (2HOL)** Linux server. It uses the official 2HOL source repositories (`twohoursonelife/OneLife`, `twohoursonelife/OneLifeData7`, and `twohoursonelife/minorGems`) rather than the original One Hour One Life repositories.

> This is a community-hosted custom server setup, not an official 2HOL service. Clients must be compatible with the server's code and data versions.

## Start a server in Codespaces

1. Open this repository on GitHub, choose **Code → Codespaces → Create codespace on main**.
2. Wait for the Codespace to finish creating.
3. In its terminal, run:

   ```bash
   bash scripts/start-2hol.sh
   ```

   On the first run, this installs any missing Linux build packages, clones the three official 2HOL repositories, checks out the same `2HOL_v...` release tag in code, data, and engine (the old `2HOL_liveServer` branch is not exposed by the current repository), builds the server, and starts it. The first build can take several minutes. On later starts, the same command starts the existing build.

4. Keep the server terminal running. The server listens on **TCP port 8005**.

To build without immediately launching the server, run `bash scripts/setup-2hol.sh` instead.

## Let friends connect over the internet

Codespaces is not a permanent game host: the server stops when the Codespace stops, and it cannot promise 24/7 uptime. For remote players, use a TCP tunnel such as Portwarp. You only need to set the tunnel up once in the Portwarp account; the CLI session must be active inside the same Codespace as the game server.

Open a **second terminal** in Codespaces, then install/sign in to Portwarp if needed:

```bash
curl -fsSL https://portwarp.com/download/install.sh | bash
pwrp login
pwrp tunnels
```

Make sure a **TCP** tunnel maps local `8005` to your public port. Start it from that second terminal (replace `1` with your tunnel number if needed):

```bash
pwrp connect 1
```

Keep both terminals open: one running `OneLifeServer`, the other running Portwarp. Share the full public hostname and port that Portwarp displays, for example `hostname.example:18118` (use your actual address, not the example). Don't share any passwords or device approval codes.

If a tunnel session is still attached to an older Codespace, stop that old session first and reconnect from the current Codespace so the tunnel reaches the correct server.

## How players join

Each friend needs a compatible Two Hours One Life client. In the client, open **Settings → Gameplay**, enable **Use Custom Server**, and enter the Portwarp hostname in the address field and the public port in the port field. Keep the port separate from the hostname. The server's local port is `8005`; players use the public port shown by Portwarp.

This setup disables the official ticket-server check for a standalone custom server. It does not provide a separate account system. If you later set a client password, share it privately with intended players.

## World persistence and backups

World database files are stored under `OneLife/server/`; the source checkouts and world files are deliberately ignored by this repository's Git rules. They remain in the Codespace filesystem when the Codespace is stopped and resumed, but **deleting the Codespace can delete the world too**.

For a consistent backup, stop the game server and run:

```bash
bash scripts/backup-world.sh
```

This creates an archive in `world-backups/`. Download that archive from the Codespaces file explorer and keep it somewhere outside the Codespace.

## Troubleshooting

- **Build fails:** copy the last 30–50 lines of output; don't delete the source folders or repeatedly rebuild from scratch.
- **Server starts but friends can't join:** confirm the server says it is listening on TCP port `8005`, the Portwarp session is live and healthy, and the displayed public port is the one entered by the client.
- **Version mismatch:** ensure the client is compatible with the server's 2HOL code and data tag versions. Don't substitute original OHOL repos or invent a version number.
- **Codespace stopped:** resume it, run `bash scripts/start-2hol.sh` in one terminal, then reconnect the Portwarp tunnel in a second terminal.

## Legacy Windows Docker scripts

The inherited `BuildServer.ps1` / `RunServer.ps1` Docker path is from the original OneClickOneServer project and has not been converted to the 2HOL repository flow. **Use the Codespaces commands above for this fork** rather than those legacy Windows Docker scripts.
