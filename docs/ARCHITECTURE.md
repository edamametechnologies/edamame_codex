# Architecture

`edamame_codex` is the OpenAI Codex CLI workstation package in the EDAMAME agent-plugin family.

## Runtime Model

1. Codex CLI writes local session transcripts under `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` (or `$CODEX_HOME/sessions`).
2. `adapters/session_prediction_adapter.mjs` discovers recent transcript files and converts them into `RawReasoningSessionPayload`.
3. `service/codex_extrapolator.mjs` forwards the raw payload to the local EDAMAME MCP endpoint via `upsert_behavioral_model_from_raw_sessions`.
4. EDAMAME generates or updates the merged behavioral model, evaluates divergence, and exposes read-only posture and verdict state.
5. `bridge/codex_edamame_mcp.mjs` exposes the local control center, healthcheck, posture-summary, and EDAMAME passthrough tools to Codex CLI.

## External Transcript Observer

EDAMAME core 1.2.3 also ships an EDAMAME-side observer that reads the same Codex session directory directly. The observer is additive and hash-skips when its payload matches the last push from this package. Operators can pause, resume, or run the observer from the EDAMAME app's AI / Config tab. If Codex is installed and the observer is paused, the `unsecured_codex` internal threat becomes active.

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
