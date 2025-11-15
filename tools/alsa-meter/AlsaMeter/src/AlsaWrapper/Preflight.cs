using System;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Reflection;
using System.Diagnostics;

namespace AlsaWrapper;

public class PreflightConfig
{
    public bool InstallMissingPackages { get; set; } = false;
    public string[] RequiredPackages { get; set; } = new[] { "libasound" };
}

public static class Preflight
{
    static string[] SonameCandidates = new[] { "libasound.so.2", "libasound.so" };

    static string MapPackageName(string name)
    {
        // map logical names to apt package names
        return name switch
        {
            "libasound" => "libasound2",
            _ => name,
        };
    }

    static PreflightConfig LoadConfig()
    {
        try
        {
            // look for appsettings.json in the working directory or the app folder
            string[] candidates = new[] {
                Path.Combine(Environment.CurrentDirectory, "appsettings.json"),
                Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) ?? ".", "appsettings.json")
            };
            foreach (var p in candidates)
            {
                if (File.Exists(p))
                {
                    var txt = File.ReadAllText(p);
                    var cfg = JsonSerializer.Deserialize<PreflightConfig>(txt);
                    if (cfg != null) return cfg;
                }
            }
        }
        catch { }
        return new PreflightConfig();
    }

    /// <summary>
    /// Try to detect libasound presence by attempting to load common sonames.
    /// If missing and config requests installation, attempt apt-get install for required packages.
    /// Returns true if soname found after any installation attempt.
    /// </summary>
    public static bool CheckAsoundAvailable()
    {
        var cfg = LoadConfig();

        bool found = false;
        foreach (var c in SonameCandidates)
        {
            try
            {
                if (NativeLibrary.TryLoad(c, out var handle))
                {
                    NativeLibrary.Free(handle);
                    found = true;
                    break;
                }
            }
            catch { }
        }

        if (found) return true;

        if (!cfg.InstallMissingPackages) return false;

        // attempt to install required packages via apt
        foreach (var pkg in cfg.RequiredPackages)
        {
            var mapped = MapPackageName(pkg);
            try
            {
                // prefer non-interactive apt
                var psi = new ProcessStartInfo("/bin/bash", $"-lc \"set -e; apt-get update -y && apt-get install -y {mapped}\"")
                {
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                using var proc = Process.Start(psi);
                if (proc != null)
                {
                    proc.WaitForExit();
                    var outp = proc.StandardOutput.ReadToEnd();
                    var err = proc.StandardError.ReadToEnd();
                    if (proc.ExitCode == 0)
                    {
                        // after install, try to load again
                        foreach (var c in SonameCandidates)
                        {
                            try
                            {
                                if (NativeLibrary.TryLoad(c, out var handle))
                                {
                                    NativeLibrary.Free(handle);
                                    return true;
                                }
                            }
                            catch { }
                        }
                    }
                    else
                    {
                        Console.WriteLine($"Preflight: apt install {mapped} failed (exit {proc.ExitCode}). stderr: {err}");
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Preflight: exception while attempting to install {mapped}: {ex.Message}");
            }
        }

        // final check
        foreach (var c in SonameCandidates)
        {
            try
            {
                if (NativeLibrary.TryLoad(c, out var handle))
                {
                    NativeLibrary.Free(handle);
                    return true;
                }
            }
            catch { }
        }

        return false;
    }
}
