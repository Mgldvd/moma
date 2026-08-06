# moma screenshot generator

Genera capturas de terminal reales de la CLI de moma: corre el binario de
verdad dentro de un pty y renderiza el resultado como PNG con marco de
ventana de terminal, en un tamaño fijo para todas las imágenes. Vive en
esta carpeta, separado del Bash de moma y del sitio Astro en `web/`.

## Setup

```bash
cd screenshots
uv sync
```

Requiere un `dist/moma` construido (`../build.sh` desde la raíz del repo).

## Comandos

| Comando | Descripción |
|---|---|
| `uv run generate.py` | Genera todas las capturas del catálogo (`catalog.yaml`) en `output/`. |
| `uv run generate.py --list` | Lista los ids de componentes disponibles. |
| `uv run generate.py --commands <id...>` | Genera solo los componentes indicados (por id o sufijo, p. ej. `resume`). |
| `uv run generate.py --output <dir>` | Cambia el directorio de salida, p. ej. `--output ../.img` para regenerar las capturas del README/docs. |
| `uv run generate.py --cols N --rows N` | Cambia el tamaño fijo de terminal usado para renderizar. |
| `uv run sync.py` | Publica lo generado en `output/` hacia `web/src/assets/screenshots/` (el sitio de docs). |
| `uv run sync.py --dry-run` | Muestra qué cambiaría `sync.py` sin copiar nada. |
| `uv run sync.py --prune` | Además borra en el sitio los archivos que ya no tengan origen en `output/`. |

Qué y cómo capturar se define en `catalog.yaml` (un componente por entrada,
con una captura principal y sus capturas complementarias).

## Ejemplos

Generar solo las capturas de `header`:

```bash
uv run generate.py --commands header
```

Generar todo el catálogo y publicarlo en el sitio en un solo paso:

```bash
uv run generate.py && uv run sync.py
```
