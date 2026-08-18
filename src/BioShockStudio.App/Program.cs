using Avalonia;
using System;

namespace BioShockStudio.App;

sealed class Program
{
    // Initialization code. Don't use any Avalonia, third-party APIs or any
    // SynchronizationContext-reliant code before AppMain is called: things aren't initialized
    // yet and stuff might break.
    [STAThread]
    public static void Main(string[] args)
    {
        // The one place an exception can escape every try/catch already in the view model: a
        // background Task that nobody awaits, or a binding callback Avalonia itself invokes. Both
        // used to vanish silently — .LogToTrace() below goes nowhere a user launching by
        // double-click will ever see. See DiagnosticLog.
        AppDomain.CurrentDomain.UnhandledException += (_, e) =>
            DiagnosticLog.Write($"UNHANDLED (terminating={e.IsTerminating}): {e.ExceptionObject}");

        TaskScheduler.UnobservedTaskException += (_, e) =>
        {
            DiagnosticLog.WriteException("Unobserved task exception", e.Exception);
            e.SetObserved();
        };

        DiagnosticLog.Write($"Log at {DiagnosticLog.FilePath}");

        BuildAvaloniaApp().StartWithClassicDesktopLifetime(args);
    }

    // Avalonia configuration, don't remove; also used by visual designer.
    public static AppBuilder BuildAvaloniaApp()
        => AppBuilder.Configure<App>()
            .UsePlatformDetect()
#if DEBUG
            
#endif
            .WithInterFont()
            .LogToTrace();
}
