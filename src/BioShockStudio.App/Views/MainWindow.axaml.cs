using System.Linq;
using System.Threading.Tasks;
using Avalonia.Controls;
using Avalonia.Platform.Storage;
using BioShockStudio.App.ViewModels;

namespace BioShockStudio.App.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();

        // The folder picker is the one thing the view model cannot do for itself, so the window
        // hands it in rather than the view model reaching for a window it should not know about.
        DataContextChanged += (_, _) =>
        {
            if (DataContext is MainViewModel model) model.PickFolder = PickFolderAsync;
        };
    }

    private async Task<string?> PickFolderAsync(string title)
    {
        var folders = await StorageProvider.OpenFolderPickerAsync(new FolderPickerOpenOptions
        {
            Title = title,
            AllowMultiple = false,
        });

        var folder = folders.FirstOrDefault();
        return folder?.TryGetLocalPath();
    }
}
