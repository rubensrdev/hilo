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

# (patron, motivo). El patron se busca en la RUTA del fichero que se va a escribir.
RULES = [
    (".pbxproj",        "el proyecto lo edita Xcode o el MCP de proyecto, nunca a mano"),
    (".xcworkspace/",   "lo genera Xcode"),
    (".xcstrings",      "las traducciones se escriben con las herramientas de String Catalog del MCP, nunca a mano"),
    ("/.git/",          "no se toca el repositorio por dentro"),
    ("DerivedData/",    "es cache de build"),
    ("/.build/",        "es cache de SPM"),
    ("/checkouts/",     "es cache de SPM"),
    ("/CLAUDE.md",      "es el contrato que te gobierna: lo edita Ruben"),
    ("/docs/specs/",    "las specs las escribe Ruben en preproduccion"),
    ("/docs/decisions/","los ADRs los escribe Ruben"),
    ("/docs/design/",   "el contrato visual y su referencia son entrada, no salida"),
    (".env",            "secretos"),
    (".pem",            "claves"),
    (".p8",             "claves"),
    (".p12",            "claves"),
    (".mobileprovision","perfiles de aprovisionamiento"),
]

# Claves que, segun la herramienta, contienen la RUTA de destino. El contenido del
# fichero (content, new_string, edits...) NUNCA se inspecciona: citar una ruta
# protegida dentro de un test o de un comentario no es escribir en ella.
PATH_KEYS = ("file_path", "filePath", "path", "notebook_path", "target_file", "destination")

EXEMPT = (".env.example", ".env.sample", ".env.template")

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
    if value.endswith(EXEMPT):
        continue
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
