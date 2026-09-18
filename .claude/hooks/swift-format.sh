#!/bin/bash
# PostToolUse hook (matcher: Write|Edit) — formatea ficheros Swift tras cada edición.
#
# Parche 16 del análisis del kit: el original prefiere swiftformat (dependencia de
# terceros) y solo cae a swift-format si falta. Hilo no admite terceros, así que aquí
# solo se usa swift-format, que viene con Xcode.
#
# Nunca bloquea (siempre exit 0): formatear es una comodidad, no un control.
#
# Aviso: el fichero cambia en disco después de escribirlo. Si un Edit posterior falla
# por old_string desajustado, hay que releer el fichero.

FILE_PATH=$(python3 -c '
import json,sys
data = json.load(sys.stdin)
print(data.get("tool_input", {}).get("file_path", ""))
')

case "$FILE_PATH" in
  *.swift) ;;
  *) exit 0 ;;
esac

[ -f "$FILE_PATH" ] || exit 0

if xcrun --find swift-format >/dev/null 2>&1; then
  xcrun swift-format format --in-place "$FILE_PATH" 2>/dev/null
fi

exit 0
