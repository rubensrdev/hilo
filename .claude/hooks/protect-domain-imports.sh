#!/bin/bash
# Hilo · PreToolUse (Write|Edit|MultiEdit y escrituras vía MCP de Xcode)
#
# Domain/ es una carpeta del target único, no un módulo: el compilador no impide
# que importe frameworks. Este hook sí. Ver ADR-000 (D1) y CLAUDE.md.
#
# Salida: exit 0 permite, exit 2 bloquea y devuelve el motivo al agente.

INPUT=$(cat)

python3 - "$INPUT" <<'PY'
import json, re, sys

FORBIDDEN = ("SwiftUI", "SwiftData", "FoundationModels", "PhotosUI", "UIKit", "Observation")

try:
    payload = json.loads(sys.argv[1])
except (json.JSONDecodeError, IndexError):
    sys.exit(0)  # entrada ilegible: no bloqueamos por ruido

tool_input = payload.get("tool_input") or {}

def strings(node):
    if isinstance(node, str):
        yield node
    elif isinstance(node, dict):
        for value in node.values():
            yield from strings(value)
    elif isinstance(node, list):
        for value in node:
            yield from strings(value)

values = list(strings(tool_input))

paths = [v for v in values if v.endswith(".swift")]
if not any("/Domain/" in p or p.startswith("Domain/") for p in paths):
    sys.exit(0)

pattern = re.compile(r"\bimport\s+(" + "|".join(FORBIDDEN) + r")\b")

found = set()
for value in values:
    if value in paths:
        continue
    found.update(pattern.findall(value))

if found:
    names = ", ".join(sorted(found))
    sys.stderr.write(
        f"BLOQUEADO: Domain/ no puede importar {names}.\n"
        "Domain/ contiene tipos valor y reglas puras: solo la biblioteca estandar y Foundation.\n"
        "Si esta pieza necesita ese framework, no pertenece a Domain/ — llevala a Persistence/, "
        "Intelligence/ o Features/, o extrae la regla pura y deja el framework fuera.\n"
        "Regla: CLAUDE.md, seccion Architecture. Decision: ADR-000 (D1).\n"
    )
    sys.exit(2)

sys.exit(0)
PY
