using BioShockStudio.Core.Game;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Shared handle on the installed game. Every test in this suite runs against real shipped bytes;
/// there are no synthetic fixtures, per the project's testing rule.
/// </summary>
public sealed class GameFixture
{
    public string? Root { get; } = GameLocator.Find();

    public bool Available => Root is not null;

    public string RequireRoot =>
        Root ?? throw new InvalidOperationException("BioShock 1 Remastered is not installed.");

    /// <summary>Smallest shipped package — cheap to parse exhaustively.</summary>
    public string EntryPackage => Path.Combine(GameLocator.MapsDirectory(RequireRoot), "Entry.bsm");

    /// <summary>Holds the first-person hands mesh and its animation package.</summary>
    public string LighthousePackage => Path.Combine(GameLocator.MapsDirectory(RequireRoot), "0-Lighthouse.bsm");

    /// <summary>Holds the shipped <c>MaterialSwitch</c> examples used to pin the candidate array.</summary>
    public string MedicalPackage => Path.Combine(GameLocator.MapsDirectory(RequireRoot), "1-Medical.bsm");

    /// <summary>The only map whose doors serialise an <c>Attachments</c> array (17 <c>MedicalDoor</c>s).</summary>
    public string FisheriesPackage => Path.Combine(GameLocator.MapsDirectory(RequireRoot), "2-Fisheries.bsm");

    /// <summary>The script package holding the first-person weapon viewmodels.</summary>
    public string WeaponPackage =>
        GameLocator.WeaponPackage(RequireRoot) ?? throw new InvalidOperationException("ShockGame.U not found.");
}

[CollectionDefinition(Name)]
public sealed class GameCollection : ICollectionFixture<GameFixture>
{
    public const string Name = "bioshock-install";
}

/// <summary>Skips a test when the game is not installed, rather than failing the suite.</summary>
public sealed class RequiresGameFactAttribute : FactAttribute
{
    public RequiresGameFactAttribute()
    {
        if (GameLocator.Find() is null)
            Skip = $"BioShock 1 Remastered not found. Set {GameLocator.PathOverrideVariable}.";
    }
}
