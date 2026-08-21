using BioShockStudio.Core.Audio;

namespace BioShockStudio.Core.Export;

/// <summary>Writes a proven native <see cref="BioShockSound"/> payload without transcoding it.</summary>
public static class SoundExporter
{
    /// <summary>
    /// Writes one recovered payload and returns its path.
    /// </summary>
    /// <remarks>
    /// MP3 data is written byte-for-byte with an <c>.mp3</c> extension. An unrecognised payload is
    /// still preserved, but as <c>.bin</c>; naming it as a playable format would be a guess.
    /// </remarks>
    public static string Write(BioShockSound sound, string directory)
    {
        Directory.CreateDirectory(directory);
        string extension = sound.Format == SoundFormat.Mp3 ? ".mp3" : ".bin";
        string path = Path.Combine(directory, SanitizeFileName(sound.Name) + extension);
        File.WriteAllBytes(path, sound.RawData);
        return path;
    }

    private static string SanitizeFileName(string value)
    {
        foreach (char invalid in Path.GetInvalidFileNameChars())
            value = value.Replace(invalid, '_');
        return value;
    }
}
