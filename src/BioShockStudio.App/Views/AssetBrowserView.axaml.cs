using Avalonia.Controls;

namespace BioShockStudio.App.Views;

/// <summary>
/// The asset browser, hosted once per asset workspace.
/// </summary>
/// <remarks>
/// No code behind it on purpose: everything it does is bound to <c>MainViewModel</c>, which is what
/// lets two instances of this control share one selection.
/// </remarks>
public partial class AssetBrowserView : UserControl
{
    public AssetBrowserView() => InitializeComponent();
}
