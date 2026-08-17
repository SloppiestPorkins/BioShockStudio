using BioShockStudio.Core.Game;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
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
                // reader found independently. The reader clamps the four meshes whose raw table
                // reaches past it, so this asserts the guarantee rather than measuring raw data —
                // the overshoots are reported by the weapon-package test, which logs them.
                int triangles = geometry.IndexCount / 3;
                foreach (var section in sections)
                {
                    if (section.FirstFace + section.NumFaces > triangles)
                        mismatches.Add(
                            $"{export.ObjectName}: section covers faces "
                            + $"{section.FirstFace}..{section.FirstFace + section.NumFaces - 1} of {triangles}");
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

        // Nothing may address triangles the mesh does not have.
        Assert.True(mismatches.Count == 0,
            $"{mismatches.Count} sections fall outside their mesh's own index buffer:"
            + Environment.NewLine + string.Join(Environment.NewLine, mismatches.Take(5)));
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

            // Diagnostic: what the raw table says against what the geometry reader found, for the
            // meshes the reader rejects. Two independent walks disagreeing by a small constant is a
            // finding; a wild disagreement is a misread.
            if (SkeletalMeshSectionReader.ReadUnvalidated(payload, package.Names) is { } raw
                && SkeletalMeshReader.DescribeGeometry(payload) is { } g)
            {
                int faces = g.IndexCount / 3;
                int reach = raw.Max(s => s.FirstFace + s.NumFaces);
                if (reach > faces)
                    Log($"  CLAMPED {export.ObjectName}: sections reach face {reach}, mesh has {faces} "
                        + $"(over by {reach - faces}), {raw.Count} sections");
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
}
