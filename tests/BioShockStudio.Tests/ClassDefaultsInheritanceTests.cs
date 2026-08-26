using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Class-default lookup across script-package imports. <c>ShockPlayer.CollisionHeight</c> is not
/// on <c>ShockGame.U</c>; the same-package walk stops at the <c>VPawn</c> import.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class ClassDefaultsInheritanceTests(GameFixture game)
{
    [RequiresGameFact]
    public void ShockPlayerCollisionHeightIsInheritedAcrossTheVPawnImport()
    {
        using var shockGame = BioShockPackage.Open(game.WeaponPackage);
        var player = shockGame.Exports.First(e => e.ObjectName == "ShockPlayer" && e.ClassIndex.IsNull);
        var defaults = new ClassDefaults(shockGame);
        var index = new PackageIndex(player.Index + 1);

        Assert.Null(defaults.Lookup(index, "CollisionHeight"));

        using var opened = new ScriptPackageSet(game.RequireRoot, shockGame);
        var hit = defaults.Lookup(index, "CollisionHeight", opened.Open);
        Assert.True(hit is not null,
            "CollisionHeight not on ShockPlayer's super chain. Last super: "
            + SuperImportDump(shockGame, player));

        Assert.Equal(UnrealPropertyType.Float, hit!.Property.Type);
        // Engine.U Pawn also ships CollisionHeight=78. Applying that would be wrong:
        // VPawn in VengeanceShared.U overrides it, and that is ShockPlayer's standing height.
        Assert.Equal("VengeanceShared.U", hit.PackageName);
        Assert.Equal("VPawn", hit.ClassName);
        Assert.Equal(68f, hit.Property.AsFloat());
    }

    private static string SuperImportDump(BioShockPackage package, ObjectExport leaf)
    {
        var current = leaf;
        for (int depth = 0; depth < 8; depth++)
        {
            var super = current.SuperIndex;
            if (super.IsImport && super.ImportIndex >= 0 && super.ImportIndex < package.Imports.Count)
                return ClassDefaults.DescribeImport(package, package.Imports[super.ImportIndex]);
            if (!super.IsExport) return $"super {package.ResolveName(super)}";
            current = package.Exports[super.ExportIndex];
        }

        return "chain too long";
    }

    private sealed class ScriptPackageSet(string gameRoot, BioShockPackage home) : IDisposable
    {
        private readonly Dictionary<string, BioShockPackage> _opened = new(StringComparer.OrdinalIgnoreCase);

        public BioShockPackage? Open(string packageName)
        {
            if (string.Equals(packageName, Path.GetFileNameWithoutExtension(home.FilePath),
                    StringComparison.OrdinalIgnoreCase))
                return home;

            if (_opened.TryGetValue(packageName, out var cached)) return cached;

            string path = Path.Combine(GameLocator.ScriptPackageDirectory(gameRoot), packageName + ".U");
            if (!File.Exists(path)) return null;

            var package = BioShockPackage.Open(path);
            _opened[packageName] = package;
            return package;
        }

        public void Dispose()
        {
            foreach (var package in _opened.Values)
                package.Dispose();
        }
    }
}
