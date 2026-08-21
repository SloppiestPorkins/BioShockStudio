using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Materials;

/// <summary>
/// One run of a mesh's index buffer together with the material it is drawn with.
/// </summary>
/// <param name="Slot">
/// Ordinal into the mesh's <c>Materials</c> array. Also the material slot index an exporter should
/// use, so the preview, the FBX and the Blender scene all number their slots the same way.
/// </param>
/// <param name="FirstIndex">Where this surface starts in the index buffer.</param>
/// <param name="IndexCount">How many indices it covers — always a whole number of triangles.</param>
/// <param name="Material">
/// The material, or null when the slot names nothing, names something outside this package, or could
/// not be decoded. A null here means <b>unknown</b>, and the surface draws untextured rather than
/// borrowing a neighbour's material.
/// </param>
/// <param name="MaterialReference">
/// The reference as stored, so a caller can say why the material is missing rather than only that it
/// is.
/// </param>
public readonly record struct MeshSurface(
    int Slot,
    int FirstIndex,
    int IndexCount,
    BioShockMaterial? Material,
    PackageIndex MaterialReference)
{
    public int TriangleCount => IndexCount / 3;

    /// <summary>Index one past the end of this surface's run.</summary>
    public int EndIndex => FirstIndex + IndexCount;
}

/// <summary>
/// Pairs a mesh's section table with its material list.
/// </summary>
/// <remarks>
/// <para>
/// <b>This is the single place that decides which triangles use which material.</b> The preview, the
/// scene JSON, the FBX exporter and the Blender exporter all call it, so they cannot disagree about
/// what a mesh looks like. Anything that resolves a material for geometry belongs here rather than in
/// a second copy next to its own consumer.
/// </para>
/// <para>
/// <b>CONFIRMED_BYTES / CORROBORATED.</b> The rule — the Nth <see cref="MeshSection"/> uses the Nth
/// entry of the object's <c>Materials</c> array — comes from Nyko's SDK and was verified field by
/// field on <c>ConeDrill</c> and <c>Turret_Cover</c>. It is corroborated game-wide: the section table
/// is read backwards from the geometry block and the <c>Materials</c> property is read forwards from
/// the start of the payload, by two readers that never consult each other, and across
/// <b>all 8,668 shipped static meshes the two counts are equal, with no exceptions</b>. See
/// <c>docs/research/staticmesh.md</c>.
/// </para>
/// </remarks>
public static class MeshSurfaceResolver
{
    /// <summary>
    /// Resolves a mesh's surfaces. Never empty for geometry that has triangles: a mesh with no
    /// section table yields one surface covering the whole index buffer.
    /// </summary>
    public static IReadOnlyList<MeshSurface> Resolve(
        BioShockPackage package, ObjectExport mesh, MeshGeometry geometry,
        IExternalMaterialSource? external = null)
    {
        if (mesh.SerialSize <= 0 || geometry.Indices.Count < 3) return [];

        var slots = MaterialReader.ReadMeshMaterialSlots(package.ReadExportData(mesh), package);
        return Resolve(package, slots, geometry, external);
    }

    /// <summary>
    /// The group an imported object belongs to, from its outer chain — <c>WP_Pistol</c> for
    /// <c>PistolShader</c>. Empty when the chain does not end in a named object.
    /// </summary>
    private static string GroupOf(BioShockPackage package, PackageIndex reference)
    {
        var current = reference;
        string last = string.Empty;

        // The chain is short; the guard is against a malformed table, not depth.
        for (int guard = 0; guard < 8; guard++)
        {
            if (current.IsImport)
            {
                if (current.ImportIndex >= package.Imports.Count) return last;
                var import = package.Imports[current.ImportIndex];
                last = import.ObjectName;
                current = import.Outer;
                continue;
            }

            if (current.IsExport && current.ExportIndex < package.Exports.Count)
                return package.Exports[current.ExportIndex].ObjectName;

            return last;
        }

        return last;
    }

    /// <summary>
    /// Resolves a mesh's surfaces from an already-read material slot list, for a caller that has the
    /// payload in hand and should not read it twice.
    /// </summary>
    public static IReadOnlyList<MeshSurface> Resolve(
        BioShockPackage package, IReadOnlyList<PackageIndex> slots, MeshGeometry geometry,
        IExternalMaterialSource? external = null)
    {
        if (geometry.Indices.Count < 3) return [];

        // Decoding the same shader once per section would re-walk its property list for every run.
        var decoded = new Dictionary<int, BioShockMaterial?>();

        BioShockMaterial? MaterialAt(int slot)
        {
            if (slot < 0 || slot >= slots.Count) return null;
            var reference = slots[slot];
            if (reference.IsNull) return null;

            if (decoded.TryGetValue(reference.Value, out var cached)) return cached;

            BioShockMaterial? material = null;

            try
            {
                if (reference.IsExport)
                {
                    material = MaterialReader.Read(package, package.Exports[reference.ExportIndex]);
                }
                else if (external is not null)
                {
                    // An import names a material in another package — the shared shaders that every
                    // NPC weapon, ammo pickup and security camera points at. Without a source for
                    // those, 433 slots across the game resolve to nothing and draw flat grey.
                    var import = package.Imports[reference.ImportIndex];
                    material = external.Find(import.ObjectName, GroupOf(package, import.Outer));
                }
            }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                           or ArgumentOutOfRangeException)
            {
                // A shader that will not decode leaves its surface untextured and visible as such.
            }

            decoded[reference.Value] = material;
            return material;
        }

        PackageIndex ReferenceAt(int slot) => slot >= 0 && slot < slots.Count ? slots[slot] : default;

        // A mesh with no section table is one surface — either a static mesh whose table did not
        // satisfy the reader's constraints, or a skeletal mesh whose section table (which sits just
        // after its socket table) could not be reached because the socket table itself did not
        // validate. A skeletal mesh with a validated socket table does carry a section table; see
        // docs/research/skeletalmesh.md "Section table — CONFIRMED_BYTES".
        if (geometry.Sections.Count == 0)
        {
            // With no table there is nothing to say which slot draws which triangle, so the mesh
            // takes its first slot that names anything. That is the pre-section behaviour, kept
            // deliberately: it is a fallback, not a claim about the data.
            int slot = 0;
            for (int i = 0; i < slots.Count; i++)
            {
                if (slots[i].IsNull) continue;
                slot = i;
                break;
            }

            return [new MeshSurface(slot, 0, geometry.Indices.Count, MaterialAt(slot), ReferenceAt(slot))];
        }

        var surfaces = new List<MeshSurface>(geometry.Sections.Count);

        for (int i = 0; i < geometry.Sections.Count; i++)
        {
            var section = geometry.Sections[i];

            // The section reader already proves the table tiles the index buffer, but this resolver
            // is what the renderer indexes with, so it clamps rather than trusting that across a
            // container it did not read.
            int first = Math.Clamp(section.FirstIndex, 0, geometry.Indices.Count);
            int count = Math.Clamp(section.IndexCount, 0, geometry.Indices.Count - first);
            if (count < 3) continue;

            surfaces.Add(new MeshSurface(i, first, count, MaterialAt(i), ReferenceAt(i)));
        }

        return surfaces;
    }

    /// <summary>
    /// The material a mesh is best described by as a whole — its first surface that resolves one.
    /// </summary>
    /// <remarks>
    /// For a details panel or a single-material consumer. It is not what the mesh is drawn with: a
    /// multi-material mesh has no one material, and asking for one is what made the drill, the cage
    /// and the backpack share the body's texture.
    /// </remarks>
    public static BioShockMaterial? Primary(IReadOnlyList<MeshSurface> surfaces) =>
        surfaces.FirstOrDefault(s => s.Material is not null).Material;
}
