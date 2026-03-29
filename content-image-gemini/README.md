# content-image-gemini

AI image generation using the [Gemini CLI](https://github.com/google-gemini/gemini-cli) and [Nano Banana](https://github.com/gemini-cli-extensions/nanobanana) extension. Headless-friendly: the plugin auto-installs the CLI and extension on first use.

## Prerequisites

- **Node.js** — required to install the Gemini CLI via `npm`
- **`GEMINI_API_KEY`** — a Gemini API key from [Google AI Studio](https://aistudio.google.com)

```bash
export GEMINI_API_KEY="your-api-key-here"
```

## Usage

The agent is a thin executor. The caller supplies a ready-made prompt — the agent runs it and returns the output path.

```text
generate image — prompt: 'A developer reviewing a system diagram, flat illustration' aspect: 16:9
generate: 'CI/CD pipeline diagram, isometric, dark background' --aspect 4:3
generate 3 variations — prompt: 'Abstract data flow between microservices'
```

Generated files are saved to `./nanobanana-output/`.

## How It Works

| Component | Role |
| --- | --- |
| `hooks/scripts/ensure-deps.sh` | Installs `@google/gemini-cli` and nanobanana extension before any `gemini` command runs |
| `agents/image-generator.md` | Thin executor: receives a prompt + params, runs the CLI, returns file path(s) |

## Manual Dependency Setup

If auto-install fails (e.g., `npm` not in PATH in your headless environment):

```bash
npm install -g @google/gemini-cli
gemini extensions install https://github.com/gemini-cli-extensions/nanobanana
```
