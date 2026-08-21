using BioShockStudio.Core.Game;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The <c>SkeletalMesh</c> section table — which triangles draw with which material.
/// </summary>
/// <remarks>
/// <para>
/// 153 skeletal meshes draw entirely in their first material because this table was never read.
/// The handoff called it "the biggest single piece of work left in Phase 1" and recorded that it
/// needs the payload walked from the front — which turned out to be shorter than expected, because
/// the socket table already sits immediately before it.
/// </para>
/// <para>
/// <b>The decode validates itself against a completely independent walk.</b> The section array must
/// end exactly where the bone map begins, and the bone map is found by searching for the vertex
/// chain from the other end of the payload. Two unrelated routes agreeing on a byte offset is the
/// evidence.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class SkeletalMeshSectionTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void SectionsAgreeWithTheGeometryFoundIndependently()
    {
        var packages = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
            .OrderBy(f => f)
            .ToList();

        int meshes = 0, withSections = 0, sectionsTotal = 0, multiMaterial = 0;
        var mismatches = new List<string>();
        var firstFaceDisagrees = new List<string>();

        foreach (string file in packages)
        {
            using var package = BioShockPackage.Open(file);

            foreach (var export in package.Exports.Where(e => package.GetClassName(e) == "SkeletalMesh"))
            {
                byte[] payload;
                try { payload = package.ReadExportData(export); }
                catch { continue; }

                if (SkeletalMeshReader.DescribeGeometry(payload) is not { } geometry) continue;
                meshes++;

                var sections = SkeletalMeshSectionReader.Read(payload, package.Names);
                if (sections is null) continue;

                withSections++;
                sectionsTotal += sections.Count;
                if (sections.Count > 1) multiMaterial++;

                // Every section the reader RETURNS must lie inside the index buffer the geometry
                // reader found independently.
                int triangles = geometry.IndexCount / 3;
                foreach (var section in sections)
                {
                    if (section.FirstFaceInBuffer + section.NumFaces > triangles)
                        mismatches.Add(
                            $"{export.ObjectName}: section covers faces "
                            + $"{section.FirstFaceInBuffer}..{section.FirstFaceInBuffer + section.NumFaces - 1} "
                            + $"of {triangles}");
                }

                // The identity the placement rests on: the sections tile the buffer exactly. This is
                // what makes "place each section after the one before it" a decode rather than a
                // convenient assumption, and it is the assertion that can fail.
                int covered = sections.Sum(s => (int)s.NumFaces);
                if (covered != triangles)
                    mismatches.Add($"{export.ObjectName}: sections total {covered} faces, "
                                   + $"the index buffer has {triangles}");

                // And the raw field that does NOT place a section, recorded rather than hidden:
                // FirstFace agrees with the running total on all but four meshes in the game.
                if (sections.Any(s => s.FirstFace != s.FirstFaceInBuffer))
                {
                    firstFaceDisagrees.Add($"{export.ObjectName}: "
                        + string.Join(", ", sections
                            .Where(s => s.FirstFace != s.FirstFaceInBuffer)
                            .Select(s => $"FirstFace {s.FirstFace} against {s.FirstFaceInBuffer}")));
                }
            }
        }

        Log($"skeletal meshes with geometry: {meshes}, with a decoded section table: {withSections}");
        Log($"  sections: {sectionsTotal}, meshes with more than one: {multiMaterial}");
        foreach (string mismatch in mismatches.Take(10)) Log("  MISMATCH " + mismatch);

        Assert.True(meshes > 100, $"only {meshes} skeletal meshes were examined");
        Assert.True(withSections > 0, "no skeletal mesh yielded a section table at all");

        // Recorded honestly: this route reaches the sections through the socket table, so a mesh
        // whose socket table does not validate is out of reach and draws in one material as before.
        // The yield is a measurement of how far the fix goes, not a target to hit.
        Log($"  yield: {withSections} of {meshes} ({(double)withSections / meshes:P0})");

        Log($"  meshes where the raw FirstFace disagrees with the running total: {firstFaceDisagrees.Count}");
        foreach (string line in firstFaceDisagrees) Log("    " + line);

        // Nothing may address triangles the mesh does not have, and every table must tile its own
        // buffer exactly.
        Assert.True(mismatches.Count == 0,
            $"{mismatches.Count} sections fall outside their mesh's own index buffer:"
            + Environment.NewLine + string.Join(Environment.NewLine, mismatches.Take(5)));

        // Four meshes in the game store a FirstFace that is not where the section begins —
        // TommyGunMESH, WP_CrossbowMesh, TunnelCollapse_Mesh, SubAnim_Mesh. What the field means on
        // those is UNKNOWN. A ceiling rather than an equality: this sweep covers the map packages,
        // and the weapon package's two are counted by the test below.
        Assert.True(firstFaceDisagrees.Count <= 4,
            $"{firstFaceDisagrees.Count} meshes disagree, up from the 4 measured:"
            + Environment.NewLine + string.Join(Environment.NewLine, firstFaceDisagrees.Take(8)));
    }

    /// <summary>
    /// A mesh known to carry several materials reports several sections.
    /// </summary>
    /// <remarks>
    /// <c>TommyGunMESH</c> is named in the handoff as one of the 153 that draw in a single material.
    /// If the table decodes it must say so — a reader that returned one section for every mesh would
    /// pass the coverage test above and change nothing.
    /// </remarks>
    [RequiresGameFact]
    public void AMultiMaterialSkeletalMeshReportsMoreThanOneSection()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage!);

        int examined = 0, multi = 0;
        var found = new List<string>();

        foreach (var export in package.Exports.Where(e => package.GetClassName(e) == "SkeletalMesh"))
        {
            byte[] payload;
            try { payload = package.ReadExportData(export); }
            catch { continue; }

            // Diagnostic: the raw FirstFace against where the section actually begins. Where these
            // differ, FirstFace used to be read as the section's position and made the table look
            // as though it overran the index buffer. It never did — the sections' face counts add
            // up to the buffer exactly. See SkeletalMeshSection.FirstFaceInBuffer.
            if (SkeletalMeshSectionReader.ReadUnvalidated(payload, package.Names) is { } raw
                && SkeletalMeshReader.DescribeGeometry(payload) is { } g)
            {
                int faces = g.IndexCount / 3;
                int reach = raw.Max(s => s.FirstFace + s.NumFaces);
                if (reach > faces)
                    Log($"  RAW FirstFace {export.ObjectName}: reaches face {reach} against {faces} in the "
                        + $"buffer (by {reach - faces}); the sections total "
                        + $"{raw.Sum(s => (int)s.NumFaces)} faces, which is the buffer exactly");
            }

            var sections = SkeletalMeshSectionReader.Read(payload, package.Names);
            if (sections is null) continue;

            examined++;
            if (sections.Count <= 1) continue;

            multi++;
            found.Add($"{export.ObjectName}: {sections.Count} sections, materials "
                      + string.Join("/", sections.Select(s => s.MaterialIndex)));
        }

        Log($"weapon package: {examined} meshes with a section table, {multi} with more than one");
        foreach (string entry in found.Take(12)) Log("  " + entry);

        Assert.True(examined > 0, "no mesh in the weapon package yielded a section table");
        Assert.True(multi > 0,
            "every mesh reported exactly one section, so the table is not distinguishing materials "
            + "and reading it changes nothing");
    }

    [RequiresGameFact]
    public void PackageAwareGeometryCarriesTheValidatedSections()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage!);
        var mesh = package.Exports.Single(export => package.GetClassName(export) == "SkeletalMesh"
            && export.ObjectName == "TommyGunMESH");
        byte[] payload = package.ReadExportData(mesh);

        var geometry = SkeletalMeshReader.ReadGeometry(payload, package.Names);
        var sections = SkeletalMeshSectionReader.Read(payload, package.Names);

        Assert.NotNull(geometry);
        Assert.NotNull(sections);
        Assert.Equal(sections!.Count, geometry!.Sections.Count);
        Assert.Equal(sections.Sum(section => (int)section.NumFaces), geometry.TriangleCount);
        Assert.Equal(sections.Select(section => section.FirstIndex), geometry.Sections.Select(section => section.FirstIndex));
    }

    [RequiresGameFact]
    public void MultiMaterialSkeletalMeshesResolveOneSurfacePerDecodedSection()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage!);
        var mesh = package.Exports.Single(export => package.GetClassName(export) == "SkeletalMesh"
            && export.ObjectName == "TommyGunMESH");
        byte[] payload = package.ReadExportData(mesh);
        var geometry = SkeletalMeshReader.ReadGeometry(payload, package.Names);

        Assert.NotNull(geometry);
        var surfaces = MeshSurfaceResolver.Resolve(package, mesh, geometry!);

        Assert.Equal(geometry.Sections.Count, surfaces.Count);
        Assert.Equal(geometry.Sections.Select(section => section.FirstIndex), surfaces.Select(surface => surface.FirstIndex));
        Assert.Equal(geometry.Sections.Select(section => section.IndexCount), surfaces.Select(surface => surface.IndexCount));
        Assert.Equal([0, 1], surfaces.Select(surface => surface.Slot));
        Assert.All(surfaces, surface => Assert.NotNull(surface.Material));
    }

    /// <summary>Exercises the package-aware geometry path the application viewport actually uses.</summary>
    [RequiresGameFact]
    public void TommyGunPreviewUsesBothMaterialRuns()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = BioShockPackage.Open(game.WeaponPackage!);
        string packageName = Path.GetFileNameWithoutExtension(game.WeaponPackage!);
        var entry = AssetCatalogService.Catalogue(package, packageName)
            .Single(item => item.ClassName == "SkeletalMesh" && item.Name == "TommyGunMESH");

        var subject = new MeshPreviewService(catalog).Load(entry);
        Assert.Equal(2, subject.Model.Surfaces.Count);
        Assert.Equal(2, subject.Model.TriangleSurface.Distinct().Count(index => index >= 0));
        Assert.All(subject.Model.Surfaces, surface => Assert.NotNull(surface.Texture));

        // Visual evidence is opt-in, but the image travels through the same surface mapping as the
        // window. Use it when reviewing a material-section regression rather than trusting counts.
        if (Environment.GetEnvironmentVariable("BIOSHOCK_SKELETAL_SECTION_SNAPSHOT") is { Length: > 0 } target)
        {
            var image = SoftwareRenderer.Render(subject.Model,
                PreviewCamera.Frame(subject.Model.Centre, subject.Model.Radius).Orbit(0.6f, 0.3f),
                new RenderOptions { ShowSkeleton = false, ShowSockets = false }, 640, 480);
            Directory.CreateDirectory(Path.GetDirectoryName(target)!);
            Core.Textures.PngWriter.Write(target, image.Rgba, image.Width, image.Height);
            Assert.True(File.Exists(target));
        }
    }
}
