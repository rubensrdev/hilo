#!/bin/bash
# Hilo · PreToolUse (Write|Edit|MultiEdit y escrituras vía MCP de Xcode)
#
# Tres reglas, y solo tres. Lo que no está aquí se escribe libremente: el diff se
# revisa antes de cada merge. Una regla de más para el trabajo cada dos por tres, y
# un hook que estorba acaba desactivado entero.
#
# Se comprueba la RUTA DE DESTINO, nunca el contenido: citar un fichero protegido
# dentro de un test o de un comentario no es escribir en él.
#
# Salida: exit 0 permite, exit 2 bloquea y devuelve el motivo al agente.

INPUT=$(cat)

python3 - "$INPUT" <<'PY'
import json, sys

RULES = [
    (".pbxproj",      "el proyecto lo edita Xcode o el MCP, nunca a mano"),
    (".xcworkspace/", "lo genera Xcode"),
    (".xcstrings",    "las traducciones se escriben con las herramientas de String Catalog del MCP, nunca a mano"),
    ("/CLAUDE.md",    "es el contrato que te gobierna: lo edita Ruben"),
]

# Claves que llevan la ruta de destino, segun la herramienta.
PATH_KEYS = ("file_path", "filePath", "path", "notebook_path", "target_file", "destination")

try:
    payload = json.loads(sys.argv[1])
except (json.JSONDecodeError, IndexError):
    sys.exit(0)

tool_input = payload.get("tool_input") or {}
mcp_xcode = str(payload.get("tool_name", "")).startswith("mcp__xcode__")

def paths(node):
    if isinstance(node, dict):
        for key, value in node.items():
            if key in PATH_KEYS and isinstance(value, str):
                yield value
            else:
                yield from paths(value)
    elif isinstance(node, list):
        for value in node:
            yield from paths(value)

for value in paths(tool_input):
    for pattern, reason in RULES:
        if pattern == ".xcstrings" and mcp_xcode:
            continue
        if pattern in value:
            sys.stderr.write(
                f"BLOQUEADO: no se escribe en {value}.\n"
                f"Motivo: {reason}.\n"
                "Si el cambio es necesario, explicalo y pideselo a Ruben.\n"
            )
            sys.exit(2)

sys.exit(0)
PY
