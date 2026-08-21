using System.Runtime.InteropServices;
using System.Text;
using BioShockStudio.Core.Audio;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Services;

namespace BioShockStudio.App.Services;

/// <summary>Plays verified embedded MP3 sounds through Windows' built-in MCI player.</summary>
/// <remarks>
/// The game stores these as ordinary MP3 payloads, so playback does not need to transcode them or
/// pull a second audio engine into the desktop application. The cached copy is the same byte-for-
/// byte file that the regular extractor writes.
/// </remarks>
internal sealed class NativeSoundPlaybackService : IDisposable
{
    private string? _alias;

    public string Play(AssetCatalogService catalog, CatalogEntry entry)
    {
        if (entry.Category != AssetCategory.Sounds)
            throw new InvalidOperationException("Only native Sound assets can be played.");

        using var lease = catalog.OpenShared(entry.Package);
        var package = lease.Package;
        var export = entry.ExportIndex >= 0 && entry.ExportIndex < package.Exports.Count
            ? package.Exports[entry.ExportIndex]
            : package.Exports
                .Where(e => e.ObjectName == entry.ObjectName && package.GetClassName(e) == SoundReader.ClassName)
                .MaxBy(e => e.SerialSize)
              ?? throw new FileNotFoundException($"'{entry.ObjectName}' is not in {entry.Package}.");

        var sound = SoundReader.Read(package, export)
            ?? throw new InvalidDataException("This Sound export does not match the proven native-audio layout.");
        if (sound.Format != SoundFormat.Mp3)
            throw new InvalidDataException("This native sound is not an MP3 payload and cannot be previewed.");

        string cache = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "BioShockStudio", "AudioCache", SafeDirectory(entry.Package), entry.ExportIndex.ToString());
        string path = SoundExporter.Write(sound, cache);

        PlayFile(path);
        return path;
    }

    /// <summary>Plays a verified MP3 or PCM WAV file through Windows MCI.</summary>
    public void PlayFile(string path)
    {
        if (!File.Exists(path)) throw new FileNotFoundException("Audio file was not found.", path);
        Stop();
        string alias = "BioShockStudio_" + Guid.NewGuid().ToString("N");
        Send($"open {Quote(path)} type mpegvideo alias {alias}");
        try
        {
            Send($"play {alias}");
            _alias = alias;
        }
        catch
        {
            SendIgnoreFailure($"close {alias}");
            throw;
        }
    }

    public void Stop()
    {
        if (_alias is null) return;
        SendIgnoreFailure($"stop {_alias}");
        SendIgnoreFailure($"close {_alias}");
        _alias = null;
    }

    public void Dispose() => Stop();

    private static string SafeDirectory(string value) => string.Concat(value.Select(c =>
        Path.GetInvalidFileNameChars().Contains(c) ? '_' : c));

    private static string Quote(string value) => '"' + value.Replace("\"", "\"\"") + '"';

    private static void Send(string command)
    {
        var error = new StringBuilder(256);
        int result = MciSendString(command, null, 0, IntPtr.Zero);
        if (result == 0) return;

        MciGetErrorString(result, error, error.Capacity);
        throw new InvalidOperationException($"Windows audio player: {error}");
    }

    private static void SendIgnoreFailure(string command)
    {
        _ = MciSendString(command, null, 0, IntPtr.Zero);
    }

    [DllImport("winmm.dll", CharSet = CharSet.Unicode, EntryPoint = "mciSendStringW")]
    private static extern int MciSendString(string command, StringBuilder? returnValue, int returnLength, IntPtr callback);

    [DllImport("winmm.dll", CharSet = CharSet.Unicode, EntryPoint = "mciGetErrorStringW")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool MciGetErrorString(int errorCode, StringBuilder errorText, int errorTextSize);
}
