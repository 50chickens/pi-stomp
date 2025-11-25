using System;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Alsa.Net;
using AlsaWrapper;

class Program
{
    static async Task<int> Main(string[] args)
    {
    string? inDevice = null;
    string? outDevice = null;
        int intervalMs = 200;
        bool loopbackTest = true; // include by default per request
        int rate = 44100;
        int channels = 2;

        for (int i = 0; i < args.Length; i++)
        {
            switch (args[i])
            {
                case "--in-device":
                    if (i + 1 < args.Length) inDevice = args[++i];
                    break;
                case "--out-device":
                    if (i + 1 < args.Length) outDevice = args[++i];
                    break;
                case "--interval-ms":
                    if (i + 1 < args.Length && int.TryParse(args[++i], out var v)) intervalMs = v;
                    break;
                case "--rate":
                    if (i + 1 < args.Length && int.TryParse(args[++i], out var r)) rate = r;
                    break;
                case "--channels":
                    if (i + 1 < args.Length && int.TryParse(args[++i], out var c)) channels = c;
                    break;
                case "--loopback-test":
                    loopbackTest = true;
                    break;
                case "--no-loopback":
                    loopbackTest = false;
                    break;
                case "-h":
                case "--help":
                    ShowHelp();
                    return 0;
            }
        }

        if (string.IsNullOrEmpty(inDevice))
        {
            Console.WriteLine("--in-device is required (ALSA capture device name)");
            ShowHelp();
            return 2;
        }

        Console.WriteLine($"In: {inDevice}  Out: {outDevice ?? "(none)"}  Interval: {intervalMs}ms  Rate: {rate}  Channels: {channels}  Loopback: {loopbackTest}");

        var cts = new CancellationTokenSource();
        Console.CancelKeyPress += (s, e) => { e.Cancel = true; cts.Cancel(); };


        // create concrete devices via the wrapper (no reflection/pinvoke)
        ISoundDevice inDeviceObj;
        try
        {
            inDeviceObj = AlsaService.CreateDevice(inDevice!, null, channels, rate);
        }
        catch (Exception ex)
        {
            Console.WriteLine("Failed to create input device via Alsa.Net: " + ex.Message);
            return 5;
        }

        ISoundDevice? outDeviceObj = null;
        if (!string.IsNullOrEmpty(outDevice))
        {
            try
            {
                outDeviceObj = AlsaService.CreateDevice(null, outDevice!, channels, rate);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Failed to create output device via Alsa.Net: " + ex.Message);
                outDeviceObj = null;
            }
        }

        // run meter loops; use typed ISoundDevice and its Record API
        var inputTask = Task.Run(() => CaptureAndMeterLoop(inDeviceObj, intervalMs, channels, rate, "IN", cts.Token));
        Task outputTask = Task.CompletedTask;
        if (outDeviceObj != null)
        {
            outputTask = Task.Run(() => CaptureAndMeterLoop(outDeviceObj, intervalMs, channels, rate, "OUT", cts.Token));
        }

        // loopback latency measurement: by default enabled when out-device is provided
        if (loopbackTest && outDeviceObj != null)
        {
            var latencyTask = Task.Run(() => LoopbackLatencyMonitor(inDeviceObj, outDeviceObj, rate, channels, cts.Token));
            await Task.WhenAll(inputTask, outputTask, latencyTask);
        }
        else
        {
            await Task.WhenAll(inputTask, outputTask);
        }

        return 0;
    }

    static void ShowHelp()
    {
        Console.WriteLine("Usage: alsa-meter --in-device <name> [--out-device <name>] [--interval-ms N] [--rate N] [--channels N] [--no-loopback]");
    }

    static void CaptureAndMeterLoop(ISoundDevice device, int intervalMs, int channels, int rate, string label, CancellationToken ct)
    {
        int recordSec = Math.Max(1, intervalMs / 1000);
        if (recordSec == 0) recordSec = 1;

        while (!ct.IsCancellationRequested)
        {
            string tmp = Path.GetTempFileName() + ".wav";
            try
            {
                device.Record((uint)recordSec, tmp);

                // read wav samples
                if (File.Exists(tmp))
                {
                    var (samples, sampleRate, numChannels) = ReadWav16(tmp);
                    var (rmsDb, peakDb) = AnalyzeSamples(samples);
                    int barWidth = 40;
                    int barLevel = (int)((Math.Pow(10, rmsDb / 20.0)) * barWidth);
                    barLevel = Math.Clamp(barLevel, 0, barWidth);
                    string bar = new string('#', barLevel).PadRight(barWidth);
                    Console.WriteLine($"{label} {rmsDb,6:F1} dB  peak {peakDb,6:F1} dB |{bar}|");
                }
                else
                {
                    Console.WriteLine($"{label}: recording file not found after Record()");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"{label}: Record failed: {ex.Message}");
            }
            finally
            {
                try { if (File.Exists(tmp)) File.Delete(tmp); } catch { }
            }

            // wait for next interval
            Task.Delay(intervalMs, ct).Wait(ct);
        }
    }

    static void LoopbackLatencyMonitor(ISoundDevice inDeviceObj, ISoundDevice outDeviceObj, int sampleRate, int channels, CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            int recordSec = 1; // short clip for latency
            string inTmp = Path.GetTempFileName() + ".wav";
            string outTmp = Path.GetTempFileName() + ".wav";

            try
            {
                var outTask = Task.Run(() => outDeviceObj.Record((uint)recordSec, outTmp));
                var inTask = Task.Run(() => inDeviceObj.Record((uint)recordSec, inTmp));
                Task.WaitAll(new Task[] { outTask, inTask }, 5000);

                if (!File.Exists(inTmp) || !File.Exists(outTmp))
                {
                    Console.WriteLine("Loopback monitor: recorded files missing");
                }
                else
                {
                    var (inSamples, _, _) = ReadWav16(inTmp);
                    var (outSamples, _, _) = ReadWav16(outTmp);
                    double latencyMs = EstimateLatencyMs(inSamples, outSamples, sampleRate, maxLagMs: 500);
                    Console.WriteLine($"Loopback latency estimate: {latencyMs:F1} ms");
                }
            }
            catch (Exception ex)
            {
                // catch and log conversion errors or other issues clearly
                Console.WriteLine("Loopback monitor error: " + ex.Message);
            }
            finally
            {
                try { if (File.Exists(inTmp)) File.Delete(inTmp); } catch { }
                try { if (File.Exists(outTmp)) File.Delete(outTmp); } catch { }
            }

            Task.Delay(1000, ct).Wait(ct);
        }
    }

    static (double rmsDb, double peakDb) AnalyzeSamples(short[] samples)
    {
        if (samples == null || samples.Length == 0) return (double.NegativeInfinity, double.NegativeInfinity);
        double sumSquares = 0;
        short peak = 0;
        for (int i = 0; i < samples.Length; i++)
        {
            short s = samples[i];
            sumSquares += (s * (double)s);
            if (Math.Abs(s) > peak) peak = (short)Math.Abs(s);
        }
        double rms = Math.Sqrt(sumSquares / samples.Length);
        double rmsDb = 20 * Math.Log10(rms / 32768.0 + 1e-12);
        double peakDb = 20 * Math.Log10(peak / 32768.0 + 1e-12);
        return (rmsDb, peakDb);
    }

    static (short[] samples, int sampleRate, int channels) ReadWav16(string path)
    {
        using var fs = File.OpenRead(path);
        using var br = new BinaryReader(fs);
        var riff = new string(br.ReadChars(4));
        if (riff != "RIFF") throw new InvalidDataException("Not a WAV file");
        br.ReadInt32(); // size
        var wave = new string(br.ReadChars(4));
        if (wave != "WAVE") throw new InvalidDataException("Not a WAVE file");

        int sampleRate = 44100;
        int bitsPerSample = 16;
        int numChannels = 1;
        while (fs.Position < fs.Length)
        {
            string chunkId = new string(br.ReadChars(4));
            int chunkSize = br.ReadInt32();
            if (chunkId == "fmt ")
            {
                int audioFormat = br.ReadInt16();
                numChannels = br.ReadInt16();
                sampleRate = br.ReadInt32();
                br.ReadInt32();
                br.ReadInt16();
                bitsPerSample = br.ReadInt16();
                if (chunkSize > 16) br.ReadBytes(chunkSize - 16);
            }
            else if (chunkId == "data")
            {
                int dataBytes = chunkSize;
                byte[] data = br.ReadBytes(dataBytes);
                int sampleCount = dataBytes / (bitsPerSample / 8);
                short[] samples = new short[sampleCount];
                Buffer.BlockCopy(data, 0, samples, 0, dataBytes);
                if (numChannels > 1)
                {
                    int frames = sampleCount / numChannels;
                    short[] mono = new short[frames];
                    for (int f = 0; f < frames; f++)
                    {
                        int sum = 0;
                        for (int c = 0; c < numChannels; c++)
                        {
                            sum += samples[f * numChannels + c];
                        }
                        mono[f] = (short)(sum / numChannels);
                    }
                    return (mono, sampleRate, numChannels);
                }
                return (samples, sampleRate, numChannels);
            }
            else
            {
                br.ReadBytes(chunkSize);
            }
        }

        return (Array.Empty<short>(), sampleRate, numChannels);
    }

    static double EstimateLatencyMs(short[] inSamples, short[] outSamples, int sampleRate, int maxLagMs = 500)
    {
        if (inSamples == null || outSamples == null || inSamples.Length == 0 || outSamples.Length == 0) return double.NaN;
        int maxLag = (int)((maxLagMs / 1000.0) * sampleRate);
        int searchLag = Math.Min(maxLag, Math.Min(inSamples.Length, outSamples.Length) / 2);

        int bestLag = 0;
        double bestCorr = double.NegativeInfinity;

        int len = Math.Min(inSamples.Length, outSamples.Length);
        int window = len;

        for (int lag = -searchLag; lag <= searchLag; lag++)
        {
            double sum = 0;
            double s1 = 0, s2 = 0;
            int count = 0;
            for (int i = 0; i < window; i++)
            {
                int j = i + lag;
                if (j < 0 || j >= window) continue;
                double a = inSamples[i];
                double b = outSamples[j];
                sum += a * b;
                s1 += a * a;
                s2 += b * b;
                count++;
            }
            if (count == 0) continue;
            double denom = Math.Sqrt(s1 * s2);
            double corr = denom > 0 ? sum / denom : 0;
            if (corr > bestCorr)
            {
                bestCorr = corr;
                bestLag = lag;
            }
        }

        double latencySeconds = -bestLag / (double)sampleRate;
        return latencySeconds * 1000.0;
    }
}
