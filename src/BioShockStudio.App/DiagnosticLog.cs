using System.Text;

namespace BioShockStudio.App;

/// <summary>
/// An always-on, append-only trail of what the window did, for a user to hand back when something
/// silently produces nothing.
/// </summary>
/// <remarks>
/// <para>
/// <b>Why this exists.</b> The app had no diagnostic trail at all: <c>Program.cs</c> called
/// <c>.LogToTrace()</c>, which goes nowhere visible for a user who launches the exe by double-click
/// rather than from a console, and there was no handler for an exception that escapes every
/// try/catch already in the view model. "Nothing happened when I clicked it" was consequently
/// undiagnosable without asking the user to run from a terminal.
/// </para>
/// <para>
/// <b>Where it writes.</b> <c>%LocalAppData%\BioShockStudio\log.txt</c>, so it is findable
/// regardless of how the exe was launched or what the current directory was. Reset on each
/// launch — this is a trail of the current session, not a growing file.
/// </para>
/// <para>
/// <b>What it is not.</b> Not a general logging framework, not configurable, not leveled. One file,
/// one purpose: read after reproducing a problem, then thrown away. If this needs more than that,
/// it has grown past what a single static class should be doing.
/// </para>
/// </remarks>
public static class DiagnosticLog
{
    private static readonly object Gate = new();
    private static readonly string Path = System.IO.Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "BioShockStudio", "log.txt");

    /// <summary>Where the log lives, so the window can tell the user where to look.</summary>
    public static string FilePath => Path;

    static DiagnosticLog()
    {
        try
        {
            Directory.CreateDirectory(System.IO.Path.GetDirectoryName(Path)!);
            File.WriteAllText(Path,
                $"BioShockStudio started {DateTime.Now:yyyy-MM-dd HH:mm:ss}{Environment.NewLine}");
        }
        catch
        {
            // Logging must never be why the app fails to start.
        }
    }

    public static void Write(string line)
    {
        lock (Gate)
        {
            try
            {
                File.AppendAllText(Path, $"{DateTime.Now:HH:mm:ss.fff} {line}{Environment.NewLine}");
            }
            catch
            {
                // A logging failure must never surface to the user as an application failure.
            }
        }
    }

    /// <summary>
    /// Records an exception with its full detail, including everything an inner exception carries —
    /// the shape that actually explains "nothing happened".
    /// </summary>
    public static void WriteException(string context, Exception ex)
    {
        var text = new StringBuilder();
        text.Append(context).Append(": ");
        for (Exception? current = ex; current is not null; current = current.InnerException)
        {
            text.Append(current.GetType().Name).Append(": ").Append(current.Message);
            if (current.InnerException is not null) text.Append(" <- ");
        }
        Write(text.ToString());
        Write("  " + ex.StackTrace?.Replace(Environment.NewLine, Environment.NewLine + "  "));
    }
}
