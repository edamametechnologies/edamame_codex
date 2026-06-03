# Architecture

`edamame_codex` is the OpenAI Codex CLI workstation package in the EDAMAME agent-plugin family.

## Runtime Model

1. Codex CLI writes local session transcripts under `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` (or `$CODEX_HOME/sessions`).
2. `adapters/session_prediction_adapter.mjs` discovers recent transcript files and converts them into `RawReasoningSessionPayload`.
3. `service/codex_extrapolator.mjs` forwards the raw payload to the local EDAMAME MCP endpoint via `upsert_behavioral_model_from_raw_sessions`.
4. EDAMAME generates or updates the merged behavioral model, evaluates divergence, and exposes read-only posture and verdict state.
5. `bridge/codex_edamame_mcp.mjs` exposes the local control center, healthcheck, posture-summary, and EDAMAME passthrough tools to Codex CLI.

## External Transcript Observer

EDAMAME core 1.2.3 ships an EDAMAME-side observer that reads `~/.codex/sessions/` directly and feeds the same ingest pipeline. The observer is the security primitive: divergence detection works as soon as Codex is **discovered** on disk, regardless of whether this Node-side package is installed. When the package **is** installed, its bridge also pushes models in-process and the observer hash-skips on duplicate payloads -- so the two paths are purely additive. Operators can pause, resume, or run the observer per agent (discovered or not) from the EDAMAME app's AI / Config tab. When the observer is paused while Codex is discovered on disk, the `unsecured_codex` internal threat becomes active on the next score cycle (the threat keys on discovery, not plugin install).

## Observer vs plugin: the value boundary

The two paths above are **not** peers, and conflating them in either
direction is wrong: this package is neither the security control nor dead
weight.

| | EDAMAME host-side observer | This package (reasoning plane) |
|---|---|---|
| Role | **Security control of record** | **Cooperative enhancement** |
| Trust model | Observer-independent: runs in the system plane, so a compromised Codex CLI cannot pause, blind, or silence it | Cooperative: Codex voluntarily declares intent; it can only *add* signal, never *weaken* a verdict |
| Needs | Codex's transcripts readable on the host (Codex **discovered** on disk) | Codex itself running this MCP bridge |
| Provides the guarantee? | **Yes** -- divergence detection works with zero plugin installed | **No** -- it adds coverage and convenience only |

The package earns its place in two ways, neither of which is the
guarantee itself:

- **Off-host coverage.** When Codex runs where the host observer cannot
  read its transcripts -- a remote box, SSH session, container, CI runner,
  VM, or a different user account -- this in-process bridge is the *only*
  path that delivers the behavioral model to EDAMAME.
- **Cooperative onboarding and UX.** MCP-native discovery, pairing, the
  in-agent read-only posture/verdict surface, health checks, intent
  export, and security-awareness rules and skills -- the turnkey ramp that
  gets a workstation monitored and lets the developer see verdicts from
  inside Codex.

Corollary: a security *decision* never moves into the package. Dismissing
findings, clearing divergence state, or any verdict-mutating capability
stays operator-only on the EDAMAME side (the MCP observer-independence
policy). The package observes and onboards; it never adjudicates.

## Host Modes

| Platform | Host of record | Notes |
|---|---|---|
| macOS / Windows | EDAMAME Security app | App-mediated pairing is preferred. |
| Linux | `edamame_posture` | Local CLI/daemon hosts the MCP endpoint. |

## Package Layout

| Path | Responsibility |
|---|---|
| `bridge/codex_edamame_mcp.mjs` | stdio MCP bridge, tool registration, control-center resource, refresh hooks |
| `bridge/edamame_client.mjs` | local HTTP MCP client for the EDAMAME host |
| `adapters/session_prediction_adapter.mjs` | Codex transcript discovery, parsing, derived hint extraction, raw-session payload build |
| `service/codex_extrapolator.mjs` | raw-session ingest orchestration, repush/recovery behavior |
| `service/control_center.mjs` | pairing, status, host actions, control-center payload |
| `service/health.mjs` | config, credential, endpoint, divergence-engine, and model health checks |
| `service/posture_facade.mjs` | compact read-only posture and verdict summary |
| `service/verdict_reader.mjs` | CLI-readable verdict and score output |
| `service/config.mjs` | config loading, path resolution, state persistence |
| `setup/install.sh` / `setup/install.ps1` | per-user installation and Codex MCP registration in `~/.codex/config.toml` |
| `tests/` | adapter, bridge, health, retry/recovery, and intent-injection coverage |
