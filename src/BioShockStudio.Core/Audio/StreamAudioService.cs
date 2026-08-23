using System.Diagnostics;
using System.Buffers.Binary;
using BioShockStudio.Core.Game;

namespace BioShockStudio.Core.Audio;

/// <summary>One shipped FSB5 stream bank, described only by fields proven in its header.</summary>
public sealed record StreamBank(string Name, string Path, int SampleCount, long Size);

/// <summary>One sample FMOD exposes from a streamed bank.</summary>
public sealed record StreamSample(int Index, string? Name);

/// <summary>
/// Enumerates BioShock's streamed FSB5 banks and delegates decoding to the game's 32-bit FMOD Ex
/// runtime through the companion x86 helper.
/// </summary>
public sealed class StreamAudioService
{
    /// <summary>Reads the bank header without interpreting sample metadata.</summary>
    public IReadOnlyList<StreamBank> List(string gameRoot)
    {
        string directory = GameLocator.StreamAudioDirectory(gameRoot);
        if (!Directory.Exists(directory)) return [];

        var banks = new List<StreamBank>();
        byte[] header = new byte[12];
        // The English banks end in .fsb, while the shipped localised copies use suffixes such as
        // .deu_fsb. The header, not the extension, establishes that a file is an FSB5 bank.
        foreach (string path in Directory.EnumerateFiles(directory).Order(StringComparer.OrdinalIgnoreCase))
        {
            using var input = File.OpenRead(path);
            if (input.Read(header) != header.Length || !header.AsSpan(0, 4).SequenceEqual("FSB5"u8)) continue;

            int samples = BinaryPrimitives.ReadInt32LittleEndian(header[8..12]);
            if (samples < 0) continue;
            banks.Add(new StreamBank(Path.GetFileName(path), path, samples, input.Length));
        }
        return banks;
    }

    /// <summary>Runs the packaged x86 decoder and returns the WAV it wrote.</summary>
    public async Task<string> DecodeAsync(
        string gameRoot, StreamBank bank, int subsoundIndex, string outputPath, CancellationToken cancellation = default)
    {
        if (subsoundIndex < 0 || subsoundIndex >= bank.SampleCount)
            throw new ArgumentOutOfRangeException(nameof(subsoundIndex),
                $"Choose an item from 0 to {Math.Max(0, bank.SampleCount - 1)}.");

        string? parent = Path.GetDirectoryName(outputPath);
        if (string.IsNullOrWhiteSpace(parent)) throw new ArgumentException("The output path needs a directory.", nameof(outputPath));
        Directory.CreateDirectory(parent);

        var result = await RunHelperAsync(gameRoot, bank, [outputPath, subsoundIndex.ToString()], cancellation);
        if (result.ExitCode != 0 || !File.Exists(outputPath))
            throw new InvalidDataException(result.Output);
        return outputPath;
    }

    /// <summary>Asks FMOD for every subsound name in a bank. A blank name stays blank rather than guessed.</summary>
    public async Task<IReadOnlyList<StreamSample>> ListSamplesAsync(
        string gameRoot, StreamBank bank, CancellationToken cancellation = default)
    {
        var result = await RunHelperAsync(gameRoot, bank, ["--list"], cancellation);
        if (result.ExitCode != 0) throw new InvalidDataException(result.Output);

        var samples = new List<StreamSample>();
        foreach (string line in result.StandardOutput.Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries))
        {
            int tab = line.IndexOf('\t');
            if (tab <= 0 || !int.TryParse(line[..tab], out int index) || index < 0) continue;
            string name = line[(tab + 1)..].Trim();
            samples.Add(new StreamSample(index, name.Length == 0 ? null : name));
        }

        if (samples.Count != bank.SampleCount)
            throw new InvalidDataException($"FMOD listed {samples.Count} items, but this bank header declares {bank.SampleCount}.");
        return samples;
    }

    private static async Task<HelperResult> RunHelperAsync(
        string gameRoot, StreamBank bank, IReadOnlyList<string> arguments, CancellationToken cancellation)
    {
        string runtime = GameLocator.FmodRuntime(gameRoot);
        if (!File.Exists(runtime)) throw new FileNotFoundException("The game's x86 FMOD runtime was not found.", runtime);

        string helper = ResolveHelper()
            ?? throw new FileNotFoundException("FmodFsbDecoder.exe was not found beside the application.");

        var start = new ProcessStartInfo(helper)
        {
            UseShellExecute = false,
            CreateNoWindow = true,
            RedirectStandardError = true,
            RedirectStandardOutput = true,
        };
        start.ArgumentList.Add(runtime);
        start.ArgumentList.Add(bank.Path);
        foreach (string argument in arguments) start.ArgumentList.Add(argument);

        using var process = Process.Start(start)
            ?? throw new InvalidOperationException("Could not start the x86 FMOD decoder.");
        // Drain both redirected pipes concurrently. A large --list response can fill stdout's OS
        // pipe while the parent waits for stderr EOF, deadlocking the helper and caller.
        Task<string> stderrTask = process.StandardError.ReadToEndAsync(cancellation);
        Task<string> stdoutTask = process.StandardOutput.ReadToEndAsync(cancellation);
        await process.WaitForExitAsync(cancellation);
        string[] output = await Task.WhenAll(stderrTask, stdoutTask);
        string stderr = output[0];
        string stdout = output[1];
        return new HelperResult(process.ExitCode, stdout, (stderr + Environment.NewLine + stdout).Trim());
    }

    private sealed record HelperResult(int ExitCode, string StandardOutput, string Output);

    private static string? ResolveHelper()
    {
        string? configured = Environment.GetEnvironmentVariable("BIOSHOCK_FMOD_HELPER");
        string[] candidates =
        [
            configured ?? string.Empty,
            Path.Combine(AppContext.BaseDirectory, "tools", "FmodFsbDecoder.exe"),
            Path.Combine(Environment.CurrentDirectory, "artifacts", "tools", "FmodFsbDecoder.exe"),
            Path.Combine(Environment.CurrentDirectory, "artifacts", "app", "tools", "FmodFsbDecoder.exe"),
        ];
        return candidates.FirstOrDefault(path => !string.IsNullOrWhiteSpace(path) && File.Exists(path));
    }
}
