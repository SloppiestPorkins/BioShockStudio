using BioShockStudio.Core.Game;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// How materials refer to cubemaps — which turns out to be: they do not.
/// </summary>
/// <remarks>
/// <para>
/// Gate 1 item 4's "environment/cubemap inputs". The expectation going in was that a material binds
/// a cubemap the way it binds any other texture, and that the binding was being dropped because
/// <c>MaterialReader</c> requires a binding to resolve to class <c>Texture</c> and a <c>Cubemap</c>
/// is not one. <b>That was wrong.</b> Across all 33 packages, 6,179 cubemap-named properties appear
/// on 5,726 materials and <b>none of them is an object reference to a cubemap</b>: they are two
/// bools and a float.
/// </para>
/// <para>
/// So the material declares <i>that</i> it wants a specular cubemap and <i>how strongly</i>, and
/// never <i>which</i>. Cubemap identity is <c>UNKNOWN</c> and is not on the material — it has to
/// come from the level or from a global. The 287 cubemaps themselves decode completely
/// (<see cref="CubemapTests"/>), so this is a wiring gap, not a format one.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class CubemapBindingTests(GameFixture game)
{
    [RequiresGameFact]
    public void NoMaterialInTheGameBindsACubemapObject()
    {
        int declaring = 0, objectReferences = 0;
        var names = new Dictionary<string, int>(StringComparer.Ordinal);
        var falseBools = new Dictionary<string, int>(StringComparer.Ordinal);

        foreach (string mapFile in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(mapFile);

            foreach (var export in package.Exports)
            {
                if (!MaterialReader.IsMaterialClass(package.GetClassName(export))) continue;

                byte[] payload;
                try { payload = package.ReadExportData(export); }
                catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }

                List<UnrealProperty> properties;
                try { properties = UnrealPropertyReader.Read(payload, package.Names, out _); }
                catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                               or ArgumentOutOfRangeException) { continue; }

                foreach (var property in properties.Where(p => p.Type == UnrealPropertyType.Bool && !p.BoolValue))
                    falseBools[property.Name] = falseBools.GetValueOrDefault(property.Name) + 1;

                var cubemapProperties = properties
                    .Where(p => p.Name.Contains("Cubemap", StringComparison.OrdinalIgnoreCase))
                    .ToList();
                if (cubemapProperties.Count == 0) continue;

                declaring++;

                foreach (var property in cubemapProperties)
                {
                    names[property.Name] = names.GetValueOrDefault(property.Name) + 1;

                    if (property.Type != UnrealPropertyType.Object) continue;
                    if (!property.TryAsObjectReference(out var reference)) continue;
                    if (!reference.IsExport || reference.ExportIndex >= package.Exports.Count) continue;
                    if (package.GetClassName(package.Exports[reference.ExportIndex]) == CubemapReader.ClassName)
                        objectReferences++;
                }
            }
        }

        Assert.True(declaring > 5_000, $"only {declaring} materials declare a cubemap-named property");

        // The finding. If this ever becomes non-zero, cubemap identity IS on the material after all
        // and MaterialReader's Texture-class binding rule is dropping it — which is what this test
        // was written expecting to find.
        Assert.Equal(0, objectReferences);

        // The three properties that do exist, and nothing else.
        Assert.True(names.GetValueOrDefault("SpecularCubeMapBrightness") > 5_000);
        Assert.True(names.GetValueOrDefault("UseSpecularCubemaps") > 400);
        Assert.True(names.GetValueOrDefault("UseSpecularCubeMap") > 100);
        Assert.False(names.ContainsKey("ReflectionCubemap"),
            "ReflectionCubemap is written after all — the SDK name list says it exists, the shipped "
            + "game had never used it");

        // Materials serialise false bools too, so MaterialReader must read the value rather than
        // test presence. This is the evidence behind that change.
        Assert.True(falseBools.GetValueOrDefault("RealTimeReflection") > 100,
            "no material serialises RealTimeReflection=false any more, which was the proof that a "
            + "material's bool presence is not its value");

        // ...while the two flags the reader acts on are never false, so reading the value changed
        // no behaviour when it was introduced.
        Assert.False(falseBools.ContainsKey("Masked"));
        Assert.False(falseBools.ContainsKey("TwoSided"));
    }

    /// <summary>
    /// The switch and its brightness reach the decoded material.
    /// </summary>
    [RequiresGameFact]
    public void TheCubemapSwitchIsCarried()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var users = new List<BioShockMaterial>();
        foreach (var export in package.Exports)
        {
            if (!MaterialReader.IsMaterialClass(package.GetClassName(export))) continue;

            BioShockMaterial? material;
            try { material = MaterialReader.Read(package, export); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }

            if (material?.UsesSpecularCubemap == true) users.Add(material);
        }

        Assert.NotEmpty(users);

        // A material that asks for a cubemap still names none — the point of the finding.
        foreach (var material in users)
            Assert.DoesNotContain(material.Textures, t => t.Slot.Contains("Cubemap", StringComparison.OrdinalIgnoreCase));
    }
}
