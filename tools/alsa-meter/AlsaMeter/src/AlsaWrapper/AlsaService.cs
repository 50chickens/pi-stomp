using System;
using Alsa.Net;

namespace AlsaWrapper;

/// <summary>
/// Minimal wrapper around Alsa.Net for the Alsameter tool.
/// Keeps all Alsa.Net usage compiled into this library so the console app has no direct NuGet dependency.
/// </summary>
public static class AlsaService
{
    public static ISoundDevice CreateDevice(string? recordingDevice, string? playbackDevice, int channels, int sampleRate)
    {
        var settings = new SoundDeviceSettings
        {
            RecordingDeviceName = string.IsNullOrEmpty(recordingDevice) ? "default" : recordingDevice,
            PlaybackDeviceName = string.IsNullOrEmpty(playbackDevice) ? "default" : playbackDevice,
            RecordingChannels = (ushort)Math.Max(1, Math.Min(ushort.MaxValue, channels)),
            RecordingSampleRate = (uint)Math.Max(1, sampleRate)
        };

        return AlsaDeviceBuilder.Create(settings);
    }
}
