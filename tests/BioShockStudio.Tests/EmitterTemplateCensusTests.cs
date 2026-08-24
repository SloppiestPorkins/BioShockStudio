using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Pins the whole-game emitter-template census that Gate 4 item 3's Niagara mapping has to be built
/// against: what ships, where it ships, and that none of it is a truncated read.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class EmitterTemplateCensusTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryEmitterTemplateInTheGameWalksCleanlyAndShipsInItsOwnMap()
    {
        var packagesWithEmitters = new List<string>();
        var packagesWithout = new List<string>();
        var templateClasses = new Dictionary<string, int>(StringComparer.Ordinal);
        var propertyNames = new HashSet<string>(StringComparer.Ordinal);
        var staticMeshOwners = new Dictionary<string, int>(StringComparer.Ordinal);
        int emitterActors = 0, incompleteActors = 0, references = 0, imports = 0, truncated = 0;

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(file => file, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(map);
            var context = LevelAnalyzer.Analyze(package);
            var actors = context.Actors.Where(actor => actor.Emitters is not null).ToList();

            (actors.Count > 0 ? packagesWithEmitters : packagesWithout)
                .Add(Path.GetFileNameWithoutExtension(map));

            var seen = new HashSet<int>();
            foreach (var actor in actors)
            {
                emitterActors++;
                if (!actor.Emitters!.Complete) incompleteActors++;

                foreach (var template in actor.Emitters.Templates)
                {
                    references++;
                    if (template.Source.Source is not { } local) { imports++; continue; }
                    if (!template.PropertiesComplete) truncated++;
                    if (!seen.Add(local.ExportIndex)) continue;

                    string className = template.Source.ClassName;
                    templateClasses[className] = templateClasses.GetValueOrDefault(className) + 1;

                    // The typed subset is four fields wide; the census is over the whole vocabulary,
                    // so this reads the template's own property list rather than the typed record.
                    var properties = UnrealPropertyReader.Read(
                        package.ReadExportData(package.Exports[local.ExportIndex]), package.Names, out _);
                    foreach (var property in properties)
                    {
                        propertyNames.Add(property.Name);
                        if (property.Name == "StaticMesh")
                            staticMeshOwners[className] = staticMeshOwners.GetValueOrDefault(className) + 1;
                    }
                }
            }
        }

        // Emitters ship in the 20 non-localised maps that have them; `Entry` is the only
        // non-localised package without, and every other empty one carries a language suffix.
        Assert.Equal(20, packagesWithEmitters.Count);
        Assert.Equal(new[] { "Entry" },
            packagesWithout.Where(name => !name.Contains('_', StringComparison.Ordinal)).ToArray());

        Assert.Equal(1859, emitterActors);
        Assert.Equal(0, incompleteActors);
        Assert.Equal(3211, references);

        // No effect crosses a package boundary, and no template is a truncated read: the vocabulary
        // below is the whole of it, not a readable prefix.
        Assert.Equal(0, imports);
        Assert.Equal(0, truncated);

        Assert.Equal(
            new Dictionary<string, int>(StringComparer.Ordinal)
            {
                ["SpriteEmitter"] = 3084,
                ["MeshEmitter"] = 57,
                ["BeamEmitter"] = 50,
                ["MultipleRibbonEmitter"] = 13,
                ["RibbonEmitter"] = 7,
            },
            templateClasses);

        Assert.Equal(120, propertyNames.Count);

        // The one class whose visual is a mesh rather than a texture, and the reason a sprite-only
        // placeholder would be wrong rather than merely approximate.
        Assert.Equal(new Dictionary<string, int>(StringComparer.Ordinal) { ["MeshEmitter"] = 57 },
            staticMeshOwners);
    }
}
