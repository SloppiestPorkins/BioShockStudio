using System.Collections.ObjectModel;
using BioShockStudio.Core.Audio;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace BioShockStudio.App.ViewModels;

/// <summary>Stream-bank browser and transport. The banks are decoded only on a user action.</summary>
public sealed record StreamBankRow(StreamBank Bank)
{
    public string Name => Bank.Name;
    public string Detail => $"{Bank.SampleCount:N0} streams · {Size(Bank.Size)}";
    public bool IsLocalised => !Name.EndsWith(".fsb", StringComparison.OrdinalIgnoreCase);

    private static string Size(long bytes) => bytes >= 1024L * 1024 * 1024
        ? $"{bytes / (1024d * 1024 * 1024):0.#} GB"
        : $"{bytes / (1024d * 1024):0.#} MB";
}

/// <summary>One FMOD-decoded stream entry. Its name comes from FMOD, or remains explicitly unnamed.</summary>
public sealed record StreamSampleRow(StreamBankRow Bank, StreamSample Sample)
{
    public int Index => Sample.Index;
    public string Name => Sample.Name ?? "(unnamed stream)";
    public string Display => $"{Index:D4}  {Name}";
}

public partial class MainViewModel
{
    [ObservableProperty] private StreamBankRow? _selectedStreamBank;
    [ObservableProperty] private StreamSampleRow? _selectedStreamSample;
    [ObservableProperty] private string _streamedAudioStatus = "Choose a stream bank.";
    [ObservableProperty] private bool _isStreamDecodeBusy;
    [ObservableProperty] private bool _isStreamedAudioPlaying;

    public ObservableCollection<StreamBankRow> StreamBanks { get; } = [];
    public ObservableCollection<StreamBankRow> EnglishStreamBanks { get; } = [];
    public ObservableCollection<StreamBankRow> LocalisedStreamBanks { get; } = [];
    public ObservableCollection<StreamSampleRow> StreamSamples { get; } = [];
    public bool HasStreamBank => SelectedStreamBank is not null;
    public bool HasStreamSample => SelectedStreamSample is not null;

    private void LoadStreamBanks(string gameRoot)
    {
        StreamBanks.Clear();
        EnglishStreamBanks.Clear();
        LocalisedStreamBanks.Clear();
        foreach (var bank in _streamAudio.List(gameRoot))
        {
            var row = new StreamBankRow(bank);
            StreamBanks.Add(row);
            (row.IsLocalised ? LocalisedStreamBanks : EnglishStreamBanks).Add(row);
        }
        SelectedStreamBank = EnglishStreamBanks.FirstOrDefault() ?? LocalisedStreamBanks.FirstOrDefault();
        StreamedAudioStatus = StreamBanks.Count == 0
            ? "No FSB5 stream banks were found in this install."
            : $"{StreamBanks.Count:N0} streamed FSB5 banks. Select a bank and item to decode.";
    }

    partial void OnSelectedStreamBankChanged(StreamBankRow? value)
    {
        StreamSamples.Clear();
        SelectedStreamSample = null;
        IsStreamedAudioPlaying = false;
        _soundPlayback.Stop();
        OnPropertyChanged(nameof(HasStreamBank));
        if (value is not null) _ = LoadStreamSamplesAsync(value);
    }

    partial void OnSelectedStreamSampleChanged(StreamSampleRow? value) => OnPropertyChanged(nameof(HasStreamSample));

    private async Task LoadStreamSamplesAsync(StreamBankRow selected)
    {
        StreamedAudioStatus = $"Reading {selected.Name}'s {selected.Bank.SampleCount:N0} stream names through the game FMOD runtime…";
        try
        {
            var samples = await _streamAudio.ListSamplesAsync(GamePath, selected.Bank);
            // A later bank click wins over a helper that happened to finish second.
            if (!ReferenceEquals(selected, SelectedStreamBank)) return;

            foreach (var sample in samples) StreamSamples.Add(new StreamSampleRow(selected, sample));
            SelectedStreamSample = StreamSamples.FirstOrDefault();
            StreamedAudioStatus = $"{selected.Name}: {StreamSamples.Count:N0} WAV entries listed.";
        }
        catch (Exception ex)
        {
            if (!ReferenceEquals(selected, SelectedStreamBank)) return;
            StreamedAudioStatus = $"Could not list {selected.Name}: {ex.Message}";
        }
    }

    [RelayCommand]
    private async Task PlayStreamAsync()
    {
        if (SelectedStreamSample is not { } selected || IsStreamDecodeBusy) return;
        string preview = PreviewPath(selected);
        await DecodeStreamAsync(selected, preview);
        if (!File.Exists(preview)) return;

        try
        {
            _soundPlayback.PlayFile(preview);
            IsStreamedAudioPlaying = true;
            StreamedAudioStatus = $"Playing {selected.Bank.Name}, item {selected.Index:N0}.";
        }
        catch (Exception ex)
        {
            IsStreamedAudioPlaying = false;
            StreamedAudioStatus = $"Could not play the decoded WAV: {ex.Message}";
        }
    }

    [RelayCommand]
    private void StopStream()
    {
        _soundPlayback.Stop();
        IsStreamedAudioPlaying = false;
        if (SelectedStreamSample is { } selected)
            StreamedAudioStatus = $"Stopped {selected.Bank.Name}, item {selected.Index:N0}.";
    }

    [RelayCommand]
    private async Task ExportStreamAsync()
    {
        if (SelectedStreamSample is not { } selected || IsStreamDecodeBusy) return;
        string stem = Path.GetFileNameWithoutExtension(selected.Bank.Name);
        string output = Path.Combine(OutputDirectory, "StreamedAudio", stem, $"{stem}_{selected.Index:D4}.wav");
        await DecodeStreamAsync(selected, output);
    }

    private async Task DecodeStreamAsync(StreamSampleRow selected, string output)
    {
        IsStreamDecodeBusy = true;
        IsStreamedAudioPlaying = false;
        StreamedAudioStatus = $"Decoding {selected.Bank.Name}, item {selected.Index:N0} through the game FMOD runtime…";
        try
        {
            await _streamAudio.DecodeAsync(GamePath, selected.Bank.Bank, selected.Index, output);
            StreamedAudioStatus = $"Decoded {selected.Bank.Name}, item {selected.Index:N0}.";
        }
        catch (Exception ex)
        {
            StreamedAudioStatus = $"Could not decode {selected.Bank.Name}, item {selected.Index:N0}: {ex.Message}";
        }
        finally
        {
            IsStreamDecodeBusy = false;
        }
    }

    private string PreviewPath(StreamSampleRow selected) => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "BioShockStudio", "StreamCache", Path.GetFileNameWithoutExtension(selected.Bank.Name),
        $"{selected.Index:D4}.wav");
}
