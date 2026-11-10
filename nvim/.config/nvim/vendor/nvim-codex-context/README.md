# nvim-codex-context

Plugin local adaptado de [mknn/nvim-claude-context](https://github.com/mknn/nvim-claude-context), bajo licencia MIT. Exporta el contexto del editor para que Codex pueda resolver referencias como «esta función».

## Configuración

La configuración de lazy.nvim está en `lua/plugins/codex-context.lua`. Carga el plugin al iniciar Neovim, sin dependencias adicionales.

```lua
opts = {
  output_path = "~/.codex/nvim-context.json",
  debounce_ms = 100,
  mode = "auto", -- "manual" copia JSON al ejecutar CodexContextRefresh
  enabled = true,
  include = { cwd = true, active_file = true, buffers = true, treesitter = true },
}
```

El archivo contiene `{ "instances": [...] }`. Cada instancia incluye `pid`, `timestamp` (segundos Unix), `cwd`, `buffers` y, si el buffer actual es un archivo, `active` con `file`, `line` y `col` desde 1. `active.treesitter` puede incluir `function` y `class`. No se exporta el contenido de los buffers ni una selección visual. Los cambios sin guardar no estarán disponibles para Codex al leer el archivo fuente.

Los buffers de terminal, ayuda, exploradores y otros paneles auxiliares se excluyen. Al enfocar uno de ellos, se omite `active`; el plugin no atribuye el cursor del panel al último archivo editado. Treesitter es opcional y usa las APIs de Neovim, sin cambiar la rama de nvim-treesitter ni instalar parsers.

Cada instancia actualiza su entrada mediante bloqueo y reemplazo atómico. Las actualizaciones eliminan registros de procesos que ya no existen. Al salir normalmente o deshabilitar el plugin se retira su entrada; al retirar la última se elimina el JSON. Si otra instancia mantiene el bloqueo durante más de 200 ms al cerrar, la próxima actualización de un editor activo limpiará el registro restante.

## Comandos

- `:CodexContextRefresh`: publica inmediatamente; en modo manual, copia JSON al portapapeles.
- `:CodexContextCopy`: copia el contexto de la instancia actual al portapapeles, en ambos modos.
- `:CodexContextDisable`: cancela actualizaciones y retira la instancia del archivo.
- `:CodexContextEnable`: reactiva las actualizaciones; en modo manual, copia el contexto.

El modo manual no crea ni modifica archivos. Los comandos de copia requieren un proveedor de portapapeles de Neovim. No se definen atajos por defecto.

## Codex

La instrucción global vive en `~/.codex/AGENTS.md`. Ante referencias ambiguas al editor, Codex debe leer `~/.codex/nvim-context.json`, seleccionar una instancia correspondiente al proyecto y leer el archivo fuente en la posición indicada. Las rutas explícitas del usuario tienen prioridad. Si varias instancias corresponden al proyecto, se elige la de timestamp más reciente; si persiste la ambigüedad, se pregunta.

Abre una nueva sesión de Codex después de modificar `AGENTS.md`. Para probarlo, coloca el cursor dentro de una función en Neovim y pide «explica esta función». Codex debe identificar el archivo y la posición publicados. El JSON es contexto consultado mediante instrucciones; no se inyecta automáticamente en cada mensaje.

## Pruebas

Desde este directorio ejecuta `python3 tests/test_context.py`. Las pruebas usan Neovim headless y archivos temporales, sin escribir el contexto global. La prueba del parser Lua usa el parser ya instalado y se omite si no está disponible.
