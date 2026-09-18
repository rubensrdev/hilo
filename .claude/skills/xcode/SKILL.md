---
name: xcode
description: Build, run tests, and read compiler errors/warnings for the Hilo project through the Xcode MCP server ("xcode") — never through xcodebuild. Triggers (español) — "compila", "compilar", "build", "hay errores", "lee los errores", "avisos", "warnings", "ejecuta los tests", "corre los tests", "tests en verde", "ejecuta en el simulador", "corre la app", "simulador de iPhone", "iOS 26".
---

# Xcode MCP for Hilo

The `xcode` MCP server (xcrun mcpbridge) is the only path to compile, test, and read build results in this project. `xcodebuild` and any other Xcode CLI tool are forbidden — see CLAUDE.md.

## Decision map — one tool per need, no alternatives

| Need | Tool |
|---|---|
| Compile | `BuildProject` |
| Run tests | `RunAllTests` |
| Read errors and warnings | `GetBuildLog` |
| Run in the simulator | `RunProject` |

Do not substitute `RunSomeTests` for a phase close — a phase requires the full suite (`RunAllTests`). Use `RunSomeTests` only when explicitly asked to run a subset while iterating.

## Arguments for this project

- **Scheme**: `Hilo`. Confirm it's active with `XcodeListSchemes`; if not, set it with `XcodeSwitchScheme(schemeName: "Hilo")`.
- **Simulator destination**: an iPhone running iOS 26. Call `XcodeListRunDestinations` and pick the entry whose platform is iOS Simulator, device is an iPhone, and OS version is 26.x — its `displayTitle` is the identifier every other tool expects. Set it with `XcodeSwitchRunDestination(displayTitle: <that displayTitle>)` before `BuildProject` or `RunProject`.
- **workspaceIdentifier**: omit it when only one workspace is open (the default). If ever ambiguous, get it from `XcodeListWorkspaces`.

## How to read the result

- Errors and warnings both come from `GetBuildLog`. Its `severity` parameter defaults to `error` — call it with `severity: "warning"` to also surface warnings and remarks alongside errors.
- **A phase is not closed on "build succeeded."** `BuildProject`/`RunAllTests` reporting success only means zero errors. Always follow with `GetBuildLog(severity: "warning")` — CLAUDE.md requires zero errors *and* zero warnings before a phase closes.

## If the server doesn't respond

Stop and ask Rubén. Never fall back to `xcodebuild` or any other Xcode CLI tool, even temporarily — CLAUDE.md forbids it with no exception.

## Out of scope here

- Never edit `project.pbxproj` directly.
- Never change target build settings or project configuration as a side effect of a build/test task — that's a separate, explicit task.
