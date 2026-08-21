using System;
using System.ComponentModel;
using System.Linq;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using BioShockStudio.App.ViewModels;
using BioShockStudio.Core.Services;

namespace BioShockStudio.App.Views;

/// <summary>
/// The asset browser, hosted once per asset workspace.
/// </summary>
public partial class AssetBrowserView : UserControl
{
    private MainViewModel? _model;
    private bool _syncingSelection;
    private Point? _drag;
    private bool _panning;

    public AssetBrowserView()
    {
        InitializeComponent();
        DataContextChanged += OnDataContextChanged;
        AssetGrid.SelectionChanged += OnAssetGridSelectionChanged;
        HookViewport();
    }

    private void OnDataContextChanged(object? sender, EventArgs e)
    {
        if (_model is not null) _model.PropertyChanged -= OnModelPropertyChanged;
        _model = DataContext as MainViewModel;
        if (_model is null) return;

        _model.PropertyChanged += OnModelPropertyChanged;
        SyncGridSelection(_model.SelectedAsset);
    }

    private void OnModelPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(MainViewModel.SelectedAsset) && _model is not null)
            SyncGridSelection(_model.SelectedAsset);
    }

    private void SyncGridSelection(CatalogEntry? asset)
    {
        if (ReferenceEquals(AssetGrid.SelectedItem, asset)) return;

        _syncingSelection = true;
        try { AssetGrid.SelectedItem = asset; }
        finally { _syncingSelection = false; }
    }

    private void OnAssetGridSelectionChanged(object? sender, SelectionChangedEventArgs e)
    {
        if (_syncingSelection || _model is null) return;

        // A newly added row is user intent. A removal by itself is a DataGrid implementation
        // detail, not enough evidence to clear the preview that the user just selected.
        var asset = e.AddedItems.OfType<CatalogEntry>().LastOrDefault();
        if (asset is not null && !ReferenceEquals(_model.SelectedAsset, asset))
            _model.SelectedAsset = asset;
    }

    /// <summary>
    /// The preview is inside this user control's name scope, not the main window's. Keeping its
    /// input hooks here means every browser instance gets direct manipulation, regardless of which
    /// workspace created it.
    /// </summary>
    private void HookViewport()
    {
        ViewportHost.PointerPressed += (_, e) =>
        {
            var point = e.GetCurrentPoint(ViewportHost);
            _drag = point.Position;
            _panning = point.Properties.IsMiddleButtonPressed || e.KeyModifiers.HasFlag(KeyModifiers.Shift);
            e.Pointer.Capture(ViewportHost);
        };

        ViewportHost.PointerMoved += (_, e) =>
        {
            if (_drag is not { } previous || _model is null) return;

            var position = e.GetCurrentPoint(ViewportHost).Position;
            _drag = position;
            if (_panning) _model.PanCamera(position.X - previous.X, position.Y - previous.Y);
            else _model.OrbitCamera(position.X - previous.X, position.Y - previous.Y);
            e.Handled = true;
        };

        ViewportHost.PointerReleased += (_, e) =>
        {
            _drag = null;
            _panning = false;
            e.Pointer.Capture(null);
            e.Handled = true;
        };

        ViewportHost.PointerWheelChanged += (_, e) =>
        {
            if (_model is null) return;
            _model.ZoomCamera(e.Delta.Y);
            e.Handled = true;
        };

        ViewportHost.SizeChanged += (_, e) => ResizeViewport(e.NewSize.Width, e.NewSize.Height);
        ViewportHost.AttachedToVisualTree += (_, _) => ResizeViewport(ViewportHost.Bounds.Width, ViewportHost.Bounds.Height);
    }

    private void ResizeViewport(double width, double height)
    {
        if (_model is null || width <= 0 || height <= 0) return;

        double scaling = TopLevel.GetTopLevel(ViewportHost)?.RenderScaling ?? 1.0;
        double factor = scaling * 1.6;
        double longest = Math.Max(width, height) * factor;
        if (longest > 1800) factor *= 1800 / longest;

        _model.ViewportWidth = (int)(width * factor);
        _model.ViewportHeight = (int)(height * factor);
    }

    /// <summary>
    /// Relationship rows are created lazily when an inspector expander opens. Handling the click
    /// here avoids a brittle nested-ItemsControl ancestor binding that could throw on a material's
    /// texture list before the click reached the view model.
    /// </summary>
    private void OpenRelated_Click(object? sender, RoutedEventArgs e)
    {
        if (sender is not Button { DataContext: RelatedAsset related } || _model is null) return;
        _model.OpenRelatedCommand.Execute(related);
    }
}
