#!/bin/bash
# Hilo · PreToolUse (Write|Edit|MultiEdit y escrituras vía MCP de Xcode)
#
# Ficheros que no se editan desde una sesión de agente. Algunos porque los genera
# Xcode, otros porque son el contrato que gobierna al propio agente.
#
# Salida: exit 0 permite, exit 2 bloquea y devuelve el motivo al agente.

INPUT=$(cat)

python3 - "$INPUT" <<'PY'
import json, sys

# (patron, motivo). El patron se busca en la ruta.
RULES = [
    (".pbxproj",        "el proyecto lo edita Xcode o el MCP de proyecto, nunca a mano"),
    (".xcworkspace/",   "lo genera Xcode"),
    (".xcstrings",      "lo genera el build a partir de los literales de las vistas"),
    ("/.git/",          "no se toca el repositorio por dentro"),
    ("DerivedData/",    "es cache de build"),
    ("/CLAUDE.md",      "es el contrato que te gobierna: lo edita Ruben"),
    ("/docs/specs/",    "las specs las escribe Ruben en preproduccion"),
    ("/docs/decisions/","los ADRs los escribe Ruben"),
    ("/docs/design/",   "el contrato visual y su referencia son entrada, no salida"),
    ("/.build/",        "es cache de SPM"),
    ("/checkouts/",     "es cache de SPM"),
    (".env",            "secretos"),
    (".pem",            "claves"),
    (".p8",             "claves"),
    (".p12",            "claves"),
    (".mobileprovision","perfiles de aprovisionamiento"),
]

try:
    payload = json.loads(sys.argv[1])
except (json.JSONDecodeError, IndexError):
    sys.exit(0)

def strings(node):
    if isinstance(node, str):
        yield node
    elif isinstance(node, dict):
        for value in node.values():
            yield from strings(value)
    elif isinstance(node, list):
        for value in node:
            yield from strings(value)

EXEMPT = (".env.example", ".env.sample", ".env.template")

for value in strings(payload.get("tool_input") or {}):
    if "/" not in value and not value.startswith("."):
        continue
    if value.endswith(EXEMPT):
        continue
    for pattern, reason in RULES:
        if pattern in value:
            sys.stderr.write(
                f"BLOQUEADO: no se escribe en {value}.\n"
                f"Motivo: {reason}.\n"
                "Si el cambio es necesario, explicalo y pideselo a Ruben.\n"
            )
            sys.exit(2)

sys.exit(0)
PY
