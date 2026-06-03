# KO-II Controller — MCP Server

Control your [Teenage Engineering EP-133 K.O. II](https://teenage.engineering/products/ep-133) with AI via the [Model Context Protocol](https://modelcontextprotocol.io).

Connect Claude (or any MCP-compatible AI) to your KO-II over MIDI — play patterns, compose beats, improvise melodies, and send transport commands — all from a conversation.

---

## Requirements

- macOS 26+
- Xcode 26+ (or Swift 6.3+ toolchain)
- A KO-II connected via USB

---

## Installation

```bash
# 1. Clone the repository
git clone https://github.com/xhiew/koii-controller
cd koii-controller/KOIIController

# 2. Build the release binary
swift build -c release

# 3. Note the binary path — you'll need it in the next step
echo "Binary: $(pwd)/.build/release/KOIIController"
```

---

## Setup with Claude Desktop

Open (or create) `~/Library/Application Support/Claude/claude_desktop_config.json` and add:

```json
{
  "mcpServers": {
    "koii-controller": {
      "command": "/path/to/koii-controller/KOIIController/.build/release/KOIIController"
    }
  }
}
```

Replace the path with the actual output from step 3 above. Restart Claude Desktop.

## Setup with Claude CLI (Pro plan)

If you use Claude via terminal (`claude` CLI), add the server with:

```bash
claude mcp add koii-controller /path/to/koii-controller/KOIIController/.build/release/KOIIController
```

Verify it was added:

```bash
claude mcp list
```

To remove it later:

```bash
claude mcp remove koii-controller
```

---

## Usage

Once connected, talk to Claude naturally. Some examples:

### Connect to the device

> "Connect to my KO-II"

Claude will call `list_midi_outputs` to find your device, then `connect_device` automatically.

### Play a drum beat

> "Play a 2-bar techno beat at 130 BPM"

> "Make a lo-fi hip hop groove with ghost notes on the snare"

### Play a melody

> "Play a sad melody in D minor, slow tempo"

> "Improvise something uplifting in C major over 4 bars"

### Transport control

> "Start playback"  
> "Stop"

### Using prompts

The server includes two structured prompts accessible in Claude:

- **`beat_generator`** — provide a genre, BPM, and number of bars. Claude will design and play a full drum kit pattern.
- **`jam_session`** — provide a mood, key, and scale. Claude will improvise a melodic phrase, optionally with a drum backing.

---

## Available Tools

| Tool | What it does |
|------|-------------|
| `list_midi_outputs` | Lists all MIDI ports on your Mac |
| `connect_device` | Connects to a MIDI port by name |
| `disconnect_device` | Disconnects the current device |
| `transport_start` | Sends MIDI Start (resets to bar 1) |
| `transport_stop` | Sends MIDI Stop |
| `transport_continue` | Resumes from current position |
| `play_pad` | Triggers a single pad (groups A–D, pads 1–12) |
| `play_drum_pattern` | Plays a text-grid drum pattern |
| `play_key_mode` | Plays a melodic sequence using scale degrees |
| `list_available_scales` | Lists the 11 supported scales |

---

## KO-II Pad Layout

```
Group A  MIDI 36–47    Group B  MIDI 48–59
Group C  MIDI 60–71    Group D  MIDI 72–83

Within each group:
  <G>.  = base note     (e.g. A. = 36)
  <G>0  = base + 1      (e.g. A0 = 37)
  <G>FX = base + 2      (e.g. AFX = 38)
  <G>1  = base + 3      (e.g. A1 = 39)
  ...
  <G>9  = base + 11     (e.g. A9 = 47)
```

---

## Tips

- **Drum patterns**: each character = one grid step. Never use spaces for visual alignment — they count as rest steps. Use `.` instead.
- **Melodies**: the default octave is 5 (matching KO-II's hardware default). Use `degree` values (1-based) — the server resolves them to MIDI notes automatically.
- **Scales**: ask Claude to `list_available_scales` before composing melodies — there are 11 options including pentatonic, blues, and chromatic.
- **Tempo**: always specify BPM so note durations are calculated correctly.

---

## Credits

Inspired by [mcp-koii](https://github.com/benjaminr/mcp-koii) by [@benjaminr](https://github.com/benjaminr) — a Python-based MCP server for the KO-II that sparked the idea for this Swift implementation.

---
