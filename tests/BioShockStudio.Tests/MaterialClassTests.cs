using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The game ships more material classes than <c>Shader</c>, and each names its texture slots
/// differently.
/// </summary>
/// <remarks>
/// <para>
/// The reader used to decide what was a texture binding from a list of thirteen slot names taken off
/// <c>Shader</c> and <c>FacingShader</c>. Every other class fell through it, so 522 meshes resolved a
/// material that appeared to bind nothing and drew flat — which the diagnostic sweep counted and
/// nothing else did.
/// </para>
/// <para>
/// The rule is now the one Nyko's material note describes: a binding is an <c>Object</c> property
/// whose reference resolves to a <c>Texture</c>. These tests hold both halves of that on real bytes —
/// that the class-specific slots bind, and that the object properties which are <b>not</b> textures
/// still do not.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class MaterialClassTests(GameFixture game)
{
    private string Map(string name) =>
        Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), name + ".bsm");

    private BioShockMaterial Material(BioShockPackage package, string className, string name)
    {
        var export = package.Exports
            .Where(e => package.GetClassName(e) == className
                        && string.Equals(e.ObjectName, name, StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);

        Assert.True(export is not null, $"{className} '{name}' is not in the package");

        var material = MaterialReader.Read(package, export!);
        Assert.True(material is not null, $"{className} '{name}' did not decode");
        return material!;
    }

    /// <summary>
    /// A <c>PlantShader</c> binds its base colour, normal and specular under <c>Alive*</c> names.
    /// </summary>
    [RequiresGameFact]
    public void APlantShaderBindsItsAliveSlots()
    {
        using var package = BioShockPackage.Open(Map("0-Lighthouse"));
        var kelp = Material(package, "PlantShader", "kelp_01");

        Assert.Equal("Kelp_01_Diffuse", kelp.TextureFor("AliveDiffuse"));
        Assert.Equal("Kelp_01_Normal", kelp.TextureFor("AliveNormalMap"));
        Assert.Equal("Kelp_01_Specular", kelp.TextureFor("AliveSpecularColorMap"));

        // And the base colour resolves, which is what stops the mesh drawing flat.
        Assert.Equal("Kelp_01_Diffuse", kelp.DiffuseTexture);
        Assert.Equal("Kelp_01_Normal", kelp.NormalTexture);
        Assert.Equal("Kelp_01_Specular", kelp.SpecularTexture);
    }

    /// <summary>
    /// A mesh slot must accept a class-specific shader. The material reader already understands
    /// PlantShader; rejecting it at the slot boundary made that decoder unreachable for levels.
    /// </summary>
    [RequiresGameFact]
    public void StaticMeshSlotsAcceptClassSpecificShaders()
    {
        using var package = BioShockPackage.Open(Map("0-Lighthouse"));

        var mesh = package.Exports
            .Where(export => package.GetClassName(export) == "StaticMesh")
            .FirstOrDefault(export => MaterialReader.ReadMeshMaterialSlots(
                package.ReadExportData(export), package).Any(reference =>
                    reference.IsExport
                    && package.GetClassName(package.Exports[reference.ExportIndex]) == "PlantShader"));

        Assert.True(mesh is not null, "the shipped map has no StaticMesh slot using PlantShader");
        var slots = MaterialReader.ReadMeshMaterialSlots(package.ReadExportData(mesh!), package);
        var plant = Assert.Single(slots.Where(reference => reference.IsExport
            && package.GetClassName(package.Exports[reference.ExportIndex]) == "PlantShader"));

        var material = MaterialReader.Read(package, package.Exports[plant.ExportIndex]);
        Assert.NotNull(material);
        Assert.NotNull(material!.DiffuseTexture);
    }

    /// <summary>
    /// A <c>FluidShader</c> binds two textures — and not its seven texture <i>animators</i>.
    /// </summary>
    /// <remarks>
    /// This is the test that makes the rule a decode rather than a grab. <c>ToiletWater_Shader</c>
    /// carries seven <c>Object</c> properties naming <c>TextureRotator</c> objects — UV modifiers,
    /// the <c>TexModifier</c> branch of the class tree, not textures. A rule of "any object property
    /// is a texture" binds all seven and the material reports nine textures instead of two.
    /// </remarks>
    [RequiresGameFact]
    public void AFluidShaderBindsItsTexturesAndNotItsAnimators()
    {
        using var package = BioShockPackage.Open(Map("0-Lighthouse"));
        var water = Material(package, "FluidShader", "ToiletWater_Shader");

        Assert.Equal("ToiletWater_Dif", water.TextureFor("WaterDiffuseMap"));
        Assert.Equal("ToiletWater_Norm", water.TextureFor("NormalMap"));
        Assert.Equal("ToiletWater_Dif", water.DiffuseTexture);

        foreach (string animator in new[]
                 {
                     "CoverageMaskAnimator", "DiffuseTextureAnimator1", "DiffuseTextureAnimator2",
                     "NormalTextureAnimator1", "NormalTextureAnimator2", "SpecularAnimator1",
                     "SpecularAnimator2",
                 })
        {
            Assert.Null(water.TextureFor(animator));
        }

        Assert.Equal(2, water.Textures.Count);
    }

    /// <summary>
    /// A <c>LightBeamShader</c> binds textures but has no base colour, and says so rather than
    /// picking one.
    /// </summary>
    /// <remarks>
    /// The honest answer here is null. Falling back to "the first texture bound" would make
    /// <c>FalloffMap</c> the mesh's colour, which is a confidently wrong result that no count can
    /// see — the same shape of fault as a normal map drawn as diffuse.
    /// </remarks>
    [RequiresGameFact]
    public void ALightBeamShaderBindsTexturesButReportsNoBaseColour()
    {
        using var package = BioShockPackage.Open(Map("0-Lighthouse"));
        var beam = Material(package, "LightBeamShader", "VolumeLight_Undewater");

        Assert.Equal("LightShaft_Falloff", beam.TextureFor("FalloffMap"));
        Assert.Equal("LightShaftUnd_Dust", beam.TextureFor("DustMap"));
        Assert.Null(beam.DiffuseTexture);
        Assert.Null(beam.TextureFor("DustTextureAnimator"));
    }

    /// <summary>
    /// A mesh whose material slot names a <c>Texture</c> draws with that texture.
    /// </summary>
    /// <remarks>
    /// A <c>Texture</c> is a material — the <c>BitmapMaterial</c> branch of the class tree — drawn by
    /// <c>MaterialFactory_BitmapMaterial</c>, which is diffuse and alpha straight from the one
    /// texture. 162 meshes in the game name one in a material slot instead of a shader, and reading
    /// those as if they were a <c>Shader</c> found no properties and reported a material binding
    /// nothing, while the texture sat right there as the object itself.
    /// </remarks>
    [RequiresGameFact]
    public void AMeshWhoseSlotNamesATextureDrawsWithIt()
    {
        using var package = BioShockPackage.Open(Map("1-Medical"));

        var export = package.Exports
            .Where(e => package.GetClassName(e) == "Texture"
                        && string.Equals(e.ObjectName, "newspaper_diffuse", StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);

        Assert.True(export is not null, "newspaper_diffuse is not in 1-Medical");

        var material = MaterialReader.Read(package, export!);
        Assert.True(material is not null, "a Texture-as-material did not decode");

        Assert.Equal("Texture", material!.ClassName);
        Assert.Equal("newspaper_diffuse", material.DiffuseTexture);
        Assert.Equal("newspaper_diffuse", material.TextureFor(MaterialReader.SelfSlot));

        // The reference has to point back at the export, or an exporter cannot write the file.
        var binding = Assert.Single(material.Textures);
        Assert.True(binding.Reference.IsExport);
        Assert.Equal(export!.Index, binding.Reference.ExportIndex);
    }

    /// <summary>
    /// A switch carries both a candidate array and an explicit default <c>Material</c> object. The
    /// latter is enough to render the shipped static default without pretending its runtime choice
    /// rules are understood.
    /// </summary>
    [RequiresGameFact]
    public void AMaterialSwitchFollowsItsDeclaredDefaultChild()
    {
        using var package = BioShockPackage.Open(Map("1-Medical"));
        var material = Material(package, "MaterialSwitch", "med_quarantine_switch");

        Assert.Equal("Shader", material.ClassName);
        Assert.Equal("med_quarantine_sign_diffuse_scroll_shader", material.Name);
        Assert.NotNull(material.DiffuseTexture);
    }

    [RequiresGameFact]
    public void AMaterialSequenceWalksItsNestedItemsPastTheShortArraySize()
    {
        using var package = BioShockPackage.Open(Map("1-Medical"));
        var export = package.Exports.Single(entry => package.GetClassName(entry) == "MaterialSequence"
            && entry.ObjectName == "drip_sequence");

        var sequence = MaterialSequenceReader.Read(package, export);

        Assert.NotNull(sequence);
        Assert.True(sequence!.Complete, $"only {sequence.Items.Count} of 30 sequence items walked: {sequence.Failure}");
        Assert.Equal(30, sequence.Items.Count);
        Assert.All(sequence.Items, item =>
        {
            Assert.True(item.Material.IsExport || item.Material.IsImport);
            Assert.True(float.IsFinite(item.Time));
            Assert.InRange(item.Action, (byte)0, (byte)1);
        });
        Assert.Equal(0.05f, sequence.Items[0].Time, 3);
    }

    /// <summary>
    /// Widening the rule took bindings away from nothing.
    /// </summary>
    /// <remarks>
    /// The new rule is a superset of the old list by construction — the old one required the slot
    /// name to be one of thirteen <i>and</i> the reference to resolve to a <c>Texture</c>; the new one
    /// drops the first condition. This checks that on the whole of a real package rather than trusting
    /// the argument: every material that bound a texture before still binds at least as many.
    /// </remarks>
    [RequiresGameFact]
    public void TheWiderRuleNeverBindsFewerTexturesThanTheOldSlotList()
    {
        string[] oldSlots =
        [
            "Diffuse", "NormalMap", "SpecularColorMap", "Emissive", "Subsurface", "Opacity", "Detail",
            "FacingDiffuse", "EdgeDiffuse", "FacingSpecularColorMap", "EdgeSpecularColorMap",
            "FacingEmissive", "EdgeEmissive",
        ];

        using var package = BioShockPackage.Open(Map("0-Lighthouse"));

        int examined = 0, gained = 0;

        foreach (var export in package.Exports)
        {
            if (export.SerialSize <= 0) continue;

            // Every shader class, not only the four `IsMaterialClass` names — those four are the
            // ones a mesh slot is allowed to *resolve* to, and restricting the census to them is
            // exactly the blindness this test exists to catch. A mesh slot reaching a `PlantShader`
            // is what happens in the shipped data.
            string className = package.GetClassName(export);
            if (!className.EndsWith("Shader", StringComparison.Ordinal)) continue;

            var material = MaterialReader.Read(package, export);
            if (material is null) continue;

            examined++;
            int old = material.Textures.Count(t => oldSlots.Contains(t.Slot, StringComparer.Ordinal));

            Assert.True(material.Textures.Count >= old,
                $"{material.ClassName} {material.Name} binds {material.Textures.Count} textures but "
                + $"{old} of them are on the old list — the new rule cannot lose a binding");

            if (material.Textures.Count > old) gained++;
        }

        Assert.True(examined > 100, $"only {examined} materials examined");
        Assert.True(gained > 0,
            "no material in the package binds a slot the old list missed, so this test proves nothing");
    }
}
