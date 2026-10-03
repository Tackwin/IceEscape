# Recording Arena through the control pipe

The Windows host records the game's rendered capture pass, including gameplay
and UI, through the local `ArenaControl` named pipe. Recordings are silent H.264
MP4 files at 1366 × 768. This uses the same GPU readback as `capture once`; it
does not record the desktop or other windows.

Build the game and Windows host with `jai Build.jai - game` and
`jai Build.jai - win32`. Run the host from `bin`, and make `ffmpeg.exe` available
on its `PATH`. FFmpeg must include the `libx264` encoder. Commands below run from
the repository root while Arena is already running.

## Pipe commands

```text
capture_video
capture_video status
capture_video start [fps] ["path.mp4"]
capture_video stop
```

| Command | Behavior |
| --- | --- |
| `capture_video` or `capture_video status` | Report recording state, output and diagnostic paths, counters, and errors. |
| `capture_video start` | Start at 30 FPS with a unique `captures/video_*.mp4` filename. |
| `capture_video start 60` | Start with a unique filename at 60 FPS. Integer FPS values from 1 through 60 are supported. |
| `capture_video start "captures/My Clip.mp4"` | Start at 30 FPS with the requested filename. |
| `capture_video start 24 "captures/My Clip.mp4"` | Start at 24 FPS with the requested filename. |
| `capture_video stop` | Stop accepting frames and ask the encoder to drain and finalize asynchronously. |

Only one recording or finalization can be active. Wait for `state=complete` or
`state=failed` before starting another recording. Stopping an inactive recording
returns its current status.

Use the helper's `-Body` argument to preserve the command's quotes:

```powershell
& .\tools\arena_control.ps1 -Body 'capture_video start'
Start-Sleep -Seconds 6
& .\tools\arena_control.ps1 -Body 'capture_video stop'
& .\tools\arena_control.ps1 -Body 'capture_video status'
```

For a custom filename and frame rate:

```powershell
& .\tools\arena_control.ps1 -Body 'capture_video start 60 "captures/My Arena Clip.mp4"'
```

`stop` usually first replies with `state=stopping`. Query status again until
finalization finishes; the stop reply does not mean that every queued frame has
already been encoded.

## Paths and replies

Relative paths resolve against **Arena's working directory**, not the helper's
working directory. Launching Arena from `bin` places default recordings under
`bin/captures`. The default captures directory is created automatically. Parent
directories for custom paths must already exist.

Path case and spaces are preserved. The path must end in `.mp4` and use printable
ASCII characters. The Windows ANSI host rejects UNC/device paths, alternate data
streams, reserved Windows names, trailing dots/spaces in path components, and
invalid Windows filename characters. The resolved path can be at most 229 bytes.
Double quotes are only delimiters around the complete path; there is no quote
escape syntax. Do not use `;` or `#` in paths: the existing control grammar treats
them as command separators and comments, including inside quotes.

The output is created exclusively: an existing file is an error and is never
overwritten. A separate, uniquely named `*.mp4.ffmpeg_*.log` records FFmpeg's
errors. A failed attempt can leave its output and log files for diagnosis; use a
new filename when retrying.

A status reply has this shape (paths and counters vary):

```text
ok capture_video state=recording path="C:\...\bin\captures\video_....mp4" log="C:\...\video_....mp4.ffmpeg_....log" fps=30 width=1366 height=768 frames=90 submitted=90 queued=0 pid=1234 exit=0 win32_error=0 reason="" timing=live skipped=0 readback_failures=0
```

| Field | Meaning |
| --- | --- |
| `state` | `idle`, `recording`, `stopping`, `complete`, or `failed`. |
| `path`, `log` | Absolute output path and FFmpeg diagnostic log path. |
| `fps`, `width`, `height` | Requested rate and raw capture dimensions. |
| `frames` | Frames fully written to FFmpeg's input. Final success is confirmed by `state=complete`. |
| `submitted` | Frames accepted into the writer queue, including repeated snapshots. |
| `queued` | Occupied frame slots, including the slot being written; each slot can represent several repeated frames. |
| `pid` | PID of the FFmpeg process launched for this recording (retained after completion). |
| `exit`, `win32_error`, `reason` | Encoder exit code, Windows error code, and failure description. |
| `timing` | `live` while resumed, `simulation` while paused. |
| `skipped` | Frames omitted by the live catch-up limit after a long stall. |
| `readback_failures` | Requested video readbacks that did not produce a submitted frame. |

The extra timing fields appear on status commands. Start and stop replies report
the encoder status without those fields. Failures use an `error` prefix, and the
PowerShell helper exits with code 1 when it receives an error reply. Invalid
syntax, such as `capture_video start 0`, produces the existing `error parse`
reply. A valid command can still fail because its destination exists, its
directory is missing, FFmpeg cannot start, or the encoder exits or breaks its
input pipe. Read the reply and the named log for the specific cause.

## Timing and paused stepping

While resumed, recording follows elapsed wall time at the requested FPS. A slow
render or encoder causes the latest rendered snapshot to be repeated for due
video frames. Catch-up is capped at 60 frames per submitted snapshot; excess
frames increment `skipped`. Thus ordinary stalls retain playback timing, while
very long stalls can shorten the recording. Encoded duration is the final frame
count divided by FPS.

While paused, each executed game tick advances recording time by exactly 1/60
second. The requested FPS resamples those ticks: at 30 FPS, 360 ticks produce 180
video frames, or six seconds. Idle time spent paused produces no frames. A full
encoder queue temporarily holds simulation ticks until space is available, so
paused stepping does not discard ticks to keep up with wall time.

Use `wait N` when a command batch must wait for all N ticks before stopping.
`step N` retains its existing behavior: it schedules ticks, and its immediate
reply is not a completion fence. Existing input lines, pause/resume behavior,
and `wait` ordering are unchanged. Session commands can share a semicolon line,
but every command on that line executes together: `wait` delays only subsequent
lines. Do **not** use `capture_video start; wait 360; capture_video stop` to record
360 ticks. Put those commands on separate newline-delimited lines, as in the
example below. Input commands must be on separate lines from session commands,
as before.

The offline end-level preview provides motion without a server. This example
records six seconds of deterministic preview animation (the animation itself
lasts roughly 5.24 seconds):

```powershell
& .\tools\arena_control.ps1 -Body @'
pause
preview_end_level
wait 1
capture_video start 30 "captures/End Level Preview.mp4"
wait 360
capture_video stop
'@
& .\tools\arena_control.ps1 -Body 'capture_video status'
```

Choose a fresh filename for every run, or omit the path to use a unique default.
Use `resume` to return to live play and `hide_end_level` to dismiss the preview.

## Capture pipeline and cleanup

The game renders the normal capture pass and performs GPU RGB24 readback only
when video or screenshot capture needs it. When both need the same tick, they
share that readback. Video copies RGB into four fixed writer slots, and a worker
streams the raw bytes to a hidden FFmpeg process. Repeated frames reuse a slot;
video does not encode PNGs or accumulate an entire recording in memory. Encoding
and stop finalization run outside the game/control loop.

FFmpeg writes fragmented MP4 to an already opened output handle. Filenames are
never interpolated into its command line, and no shell is used. Frames have no
audio track. `capture once`, `capture start`, and `capture stop` continue to
produce PNG screenshots independently of video. Screenshot serials skip existing
files, and screenshot writes also use exclusive file creation.

`quit` and window close stop recording and drain finalization with a bounded
shutdown wait. A blocked encoder write or stalled finalization becomes a failure
after its timeout (10 seconds for a write, 15 seconds for finalization). Cleanup
can terminate the FFmpeg process launched for this recording. Abruptly killing
Arena bypasses this cleanup and can leave a partial recording.

To inspect a completed recording:

```powershell
ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration -of default=noprint_wrappers=1 'bin/captures/My Arena Clip.mp4'
```

Fragmented MP4 may omit `nb_frames` in the stream metadata; add `-count_frames`
and request `nb_read_frames` when an actual decoded frame count is needed.

## Manual verification (3 October 2026)

Built the game DLL, server DLL, and Windows hosts with `jai Build.jai - game`,
`jai Build.jai - server`, and `jai Build.jai - win32`. No automatic tests were
added or run. The shared game/platform code also compiled and linked for WASM
using an isolated output directory; browser runtime was not exercised. The actual Arena app was controlled through `ArenaControl`:

- Offline preview: 180 decoded frames at 30 FPS, 1366 × 768, exactly 6.00 seconds.
  Decoded frames 0, 75, and 150 showed the awards and coin animation progressing.
- Localhost Welcome level: 189 decoded frames at 30 FPS, 1366 × 768, 6.30 seconds.
  All 189 decoded frame hashes differed; representative frames showed scene
  motion and the gameplay timer progressing. The server used a separate copied
  database and local terrain assets.
- Paused idle left the frame count at zero. `wait 120` at 60 FPS produced exactly
  120 frames and a decoded two-second clip.
- Screenshot once during recording, screenshot start/stop, asynchronous video
  start/stop/status, restart after failure, and quit while recording succeeded.
  The quit clip decoded to 30 frames at 30 FPS (one second).
- Existing output, missing directory, invalid FPS, missing FFmpeg on PATH, and
  forced termination of the owned encoder returned errors. The app remained
  controllable. All 68 preexisting PNG captures retained their original hashes.

FFprobe was unavailable on the verification machine, so FFmpeg decoded the
clips to count frames and inspect dimensions, rate, duration, and frame hashes.
Encoder stall timeout, disk-full behavior, and the window-close action were
reviewed in code but were not separately fault-injected or manually exercised.

The live gameplay sample is
[`Video Gameplay 20261003-160354.mp4`](../bin/captures/Video%20Gameplay%2020261003-160354.mp4),
and the offline sample is
[`Video Preview 20261003-160354.mp4`](../bin/captures/Video%20Preview%2020261003-160354.mp4).
These local verification artifacts are not part of the source commit.
