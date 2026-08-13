using BioShockStudio.Core.Assets;

namespace BioShockStudio.Core.Mesh;

/// <summary>
/// Reads a mesh's geometry given its class, so callers do not have to know which container a
/// particular asset ships in.
/// </summary>
/// <remarks>
/// The two classes are genuinely different formats — see <see cref="SkeletalMeshReader"/> and
/// <see cref="StaticMeshReader"/> — but they produce the same <see cref="MeshGeometry"/>, so
/// routing on the class name is the only place downstream code needs to care.
/// </remarks>
public static class MeshGeometryReader
{
    /// <summary>Whether this class holds geometry this tool can read at all.</summary>
    public static bool IsMeshClass(string className) =>
        className is AssetClasses.SkeletalMesh or AssetClasses.StaticMesh;

    /// <summary>
    /// Reads the geometry, or returns null when the class is not a mesh or the payload holds a
    /// layout variant that is not understood. Both readers refuse to guess.
    /// </summary>
    public static MeshGeometry? Read(string className, ReadOnlySpan<byte> payload) => className switch
    {
        AssetClasses.SkeletalMesh => SkeletalMeshReader.ReadGeometry(payload),
        AssetClasses.StaticMesh => StaticMeshReader.ReadGeometry(payload),
        _ => null,
    };
}
