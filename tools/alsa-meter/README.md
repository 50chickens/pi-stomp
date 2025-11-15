ALSA Meter (tools/alsa-meter)

This is a minimal .NET 9 console app that shows input/output levels for ALSA devices.
It was scaffolded to include a PackageReference to `Alsa.Net` (per request). The implementation
uses libasound P/Invoke as a robust fallback; if you prefer to use the `Alsa.Net` API
replace the P/Invoke code in Program.cs with calls to that package.

Build

```bash
cd tools/alsa-meter
dotnet restore
dotnet build -c Release
```

Run

```bash
# capture-only meter
dotnet run --project tools/alsa-meter -- --in-device hw:0,0 --interval-ms 200

# capture in and capture-capable output (e.g. arecord-able monitor device)
dotnet run --project tools/alsa-meter -- --in-device hw:1,0 --out-device hw:2,0 --loopback-test
```

Notes
- The app opens the ALSA device in S16_LE interleaved mode at the requested rate and channels
  using `snd_pcm_set_params` as a convenience. If your hardware uses another format or the set
  parameters call fails, you may need to open and configure the PCM with lower-level hw_params.
- `--loopback-test` simply runs both input and output meters in parallel; with a physical cable
  between output and input you can observe levels and roughly estimate latency manually. A more
  advanced latency test (cross-correlation) could be added in a follow-up.
