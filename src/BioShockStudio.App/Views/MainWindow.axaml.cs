using System.Linq;
using System.Threading.Tasks;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Platform.Storage;
using BioShockStudio.App.ViewModels;

namespace BioShockStudio.App.Views;

public partial class MainWindow : Window
{
    private Point? _drag;
    private bool _panning;

    public MainWindow()
    {
        InitializeComponent();

        // The folder picker is the one thing the view model cannot do for itself, so the window
        // hands it in rather than the view model reaching for a window it should not know about.
        DataContextChanged += (_, _) =>
        {
            if (DataContext is MainViewModel model) model.PickFolder = PickFolderAsync;
        };

        HookViewport();
        HookShortcuts();

        // Settings are written on the way out rather than on every change, so a session's fiddling
        // costs one write instead of dozens.
        Closing += (_, _) =>
        {
            if (DataContext is MainViewModel model) model.Persist(Width, Height);
        };
    }

    /// <summary>
    /// Keyboard shortcuts for the things done most often.
    /// </summary>
    /// <remarks>
    /// Handled on the tunnelling pass so they work wherever focus is, except that typing in the
    /// search box must still produce text — Space and the arrows are ignored while it has focus.
    /// </remarks>
    private void HookShortcuts()
    {
        AddHandler(KeyDownEvent, (_, e) =>
        {
            if (DataContext is not MainViewModel model) return;

            var search = this.FindControl<TextBox>("SearchBox");
            bool typing = search?.IsFocused == true;

            if (e.KeyModifiers.HasFlag(KeyModifiers.Control) && e.Key == Key.F)
            {
                search?.Focus();
                search?.SelectAll();
                e.Handled = true;
                return;
            }

            switch (e.Key)
            {
                case Key.Escape when typing:
                    model.ClearSearchCommand.Execute(null);
                    e.Handled = true;
                    break;

                case Key.Space when !typing && model.HasViewport:
                    model.TogglePlayCommand.Execute(null);
                    e.Handled = true;
                    break;

                case Key.Left when !typing && model.LastFrame > 0:
                    model.PreviousFrameCommand.Execute(null);
                    e.Handled = true;
                    break;

                case Key.Right when !typing && model.LastFrame > 0:
                    model.NextFrameCommand.Execute(null);
                    e.Handled = true;
                    break;
            }
        }, RoutingStrategies.Tunnel);
    }

    /// <summary>
    /// Wires mouse input on the 3D preview: drag to orbit, shift or middle drag to pan, wheel to
    /// zoom. The view model is told about gestures in pixels and owns what they mean.
    /// </summary>
    private void HookViewport()
    {
        var host = this.FindControl<Border>("ViewportHost");
        if (host is null) return;

        host.PointerPressed += (_, e) =>
        {
            var point = e.GetCurrentPoint(host);
            _drag = point.Position;
            _panning = point.Properties.IsMiddleButtonPressed
                       || e.KeyModifiers.HasFlag(KeyModifiers.Shift);
            e.Pointer.Capture(host);
        };

        host.PointerMoved += (_, e) =>
        {
            if (_drag is not { } previous || DataContext is not MainViewModel model) return;

            var position = e.GetCurrentPoint(host).Position;
            double dx = position.X - previous.X;
            double dy = position.Y - previous.Y;
            _drag = position;

            if (_panning) model.PanCamera(dx, dy);
            else model.OrbitCamera(dx, dy);
        };

        host.PointerReleased += (_, e) =>
        {
            _drag = null;
            _panning = false;
            e.Pointer.Capture(null);
        };

        host.PointerWheelChanged += (_, e) =>
        {
            if (DataContext is MainViewModel model) model.ZoomCamera(e.Delta.Y);
        };

        // Render at the size the viewport actually is, so the image is not scaled up and blurred.
        host.SizeChanged += (_, e) =>
        {
            if (DataContext is not MainViewModel model) return;
            model.ViewportWidth = (int)e.NewSize.Width;
            model.ViewportHeight = (int)e.NewSize.Height;
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
