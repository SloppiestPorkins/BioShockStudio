using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The section table: which triangles a <c>StaticMesh</c> draws with which material.
/// </summary>
/// <remarks>
/// The layout came from Nyko's SDK (<c>bioshock1-bsm.md</c> §C.4) after this project failed to find
/// it from bytes alone. These tests are what makes it this project's own claim rather than a
/// borrowed one: the sections are checked against geometry decoded independently of them.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class StaticMeshSectionTests(GameFixture game)
{
    private string Map(string name) =>
        Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), name + ".bsm");

    private MeshGeometry Read(string map, string mesh)
    {
        using var package = BioShockPackage.Open(Map(map));
        var export = package.Exports
            .Where(e => package.GetClassName(e) == "StaticMesh"
                        && string.Equals(e.ObjectName, mesh, StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);
        Assert.True(export is not null, $"{mesh} is not in {map}");

        var geometry = StaticMeshReader.ReadGeometry(package.ReadExportData(export!));
        Assert.True(geometry is not null, $"{mesh} produced no geometry");
        return geometry!;
    }

    /// <summary>
    /// The two meshes the layout was verified on. Each section field is checked against the mesh's
    /// own decoded geometry, which the section reader does not consult.
    /// </summary>
    [RequiresGameFact]
    public void SectionsAgreeWithTheDecodedGeometry()
    {
        foreach (var (map, mesh) in new[] { ("1-Medical", "ConeDrill"), ("1-Medical", "Turret_Cover") })
        {
            var geometry = Read(map, mesh);

            Assert.NotEmpty(geometry.Sections);
            Assert.Equal(geometry.Indices.Count, geometry.Sections.Sum(s => s.IndexCount));

            int covered = 0;
            foreach (var section in geometry.Sections)
            {
                Assert.Equal(covered, section.FirstIndex);
                Assert.InRange(section.LastVertex, section.FirstVertex, geometry.Vertices.Count - 1);
                covered += section.IndexCount;
            }
        }
    }

    /// <summary>
    /// Game-wide: where a mesh declares sections they must tile its index buffer exactly and stay
    /// inside its vertex array. A reading that were merely plausible would not survive 8,668 meshes.
    /// </summary>
    [RequiresGameFact]
    public void EverySectionTableTilesItsIndexBuffer()
    {
        int meshes = 0, withSections = 0, multiSection = 0;

        foreach (string map in Directory.GetFiles(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "*.bsm"))
        {
            using var package = BioShockPackage.Open(map);
            foreach (var export in package.Exports.Where(e => package.GetClassName(e) == "StaticMesh"))
            {
                MeshGeometry? geometry;
                try { geometry = StaticMeshReader.ReadGeometry(package.ReadExportData(export)); }
                catch { continue; }
                if (geometry is null) continue;

                meshes++;
                if (geometry.Sections.Count == 0) continue;

                withSections++;
                if (geometry.Sections.Count > 1) multiSection++;

                Assert.Equal(geometry.Indices.Count, geometry.Sections.Sum(s => s.IndexCount));

                int covered = 0;
                foreach (var section in geometry.Sections)
                {
                    Assert.Equal(covered, section.FirstIndex);
                    Assert.True(section.LastVertex < geometry.Vertices.Count,
                        $"{export.ObjectName}: section reaches vertex {section.LastVertex} of {geometry.Vertices.Count}");
                    covered += section.IndexCount;
                }
            }
        }

        Assert.True(meshes > 5_000, $"only {meshes} meshes read");

        // The check would pass vacuously if nothing resolved a table, and the whole point of the
        // table is the meshes that have more than one.
        Assert.True(withSections > meshes / 2,
            $"only {withSections} of {meshes} meshes resolved a section table");
        Assert.True(multiSection > 0, "no mesh resolved more than one section");
    }
}
