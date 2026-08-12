using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Services;

/// <summary>
/// Something that attaches to a host's socket — a first-person weapon, typically.
/// </summary>
/// <param name="Confidence">
/// <c>Confirmed</c> when the game data states the relationship: the attachment's own skeleton is
/// rooted at the bone the host's socket names. <c>Likely</c> when only the names line up.
/// </param>
/// <param name="Evidence">What was actually observed, in words, so the claim can be checked.</param>
public sealed record AttachmentCandidate(
    string Socket,
    string SocketBone,
    string Package,
    string Group,
    string MeshObject,
    string AnimationPackageObject,
    string Confidence,
    string Evidence);

/// <summary>
/// Works out what belongs with what: which asset attaches to which socket, and on what evidence.
/// </summary>
/// <remarks>
/// <para>
/// The load-bearing case is the first-person set. A hands mesh declares a socket named after a
/// weapon (<c>Pistol</c>) bound to a bone (<c>R_Grip</c>); the weapon's own skeleton, in
/// <c>ShockGame.U</c>, is rooted at a bone of that name. That root match is what turns a naming
/// coincidence into a stated relationship, so it is what this checks — and when it does not hold,
/// the candidate is reported as <c>Likely</c> rather than quietly promoted.
/// </para>
/// <para>
/// The weapon rigs are never merged into the host skeleton. They are separate assets played
/// together at the socket.
/// </para>
/// </remarks>
public sealed class AssetContextService(AssetCatalogService catalog)
{
    /// <summary>Group prefix the game uses for weapon assets.</summary>
    private const string WeaponGroupPrefix = "WP_";

    /// <summary>
    /// Attachment candidates for a host asset, one per socket that resolves to a real asset.
    /// </summary>
    public IReadOnlyList<AttachmentCandidate> Attachments(CatalogEntry host, CancellationToken cancellation = default)
    {
        var results = new List<AttachmentCandidate>();

        IReadOnlyList<MeshSocket> sockets;
        using (var package = BioShockPackage.Open(catalog.PackageFile(host.Package)))
        {
            var meshExport = package.Exports
                .Where(e => package.GetClassName(e) == AssetClasses.SkeletalMesh
                            && string.Equals(AssetContextResolver.TopLevelGroup(package, e), host.Group,
                                StringComparison.OrdinalIgnoreCase))
                .MaxBy(e => e.SerialSize);

            if (meshExport is null) return results;
            sockets = SkeletalMeshReader.ReadSockets(package.ReadExportData(meshExport), package.Names);
        }

        if (sockets.Count == 0) return results;

        // Weapon viewmodels are not in the map packages; they are in the script package.
        foreach (string packageName in catalog.Packages)
        {
            cancellation.ThrowIfCancellationRequested();

            using var package = BioShockPackage.Open(catalog.PackageFile(packageName));
            var groups = GroupsWithSkeletons(package);
            if (groups.Count == 0) continue;

            foreach (var socket in sockets)
            {
                string expected = WeaponGroupPrefix + socket.Name;
                if (!groups.TryGetValue(expected, out var candidate)) continue;

                var (confidence, evidence) = Assess(package, candidate, socket);

                results.Add(new AttachmentCandidate(
                    socket.Name, socket.BoneName, packageName, candidate.Group,
                    candidate.Mesh, candidate.Wrapper, confidence, evidence));
            }
        }

        return results
            .GroupBy(r => r.Socket, StringComparer.OrdinalIgnoreCase)
            .Select(g => g.OrderBy(r => r.Confidence == "Confirmed" ? 0 : 1).First())
            .OrderBy(r => r.Socket, StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private readonly record struct GroupAssets(string Group, string Mesh, string Wrapper);

    private static Dictionary<string, GroupAssets> GroupsWithSkeletons(BioShockPackage package)
    {
        var meshes = new Dictionary<string, ObjectExport>(StringComparer.OrdinalIgnoreCase);
        var wrappers = new Dictionary<string, ObjectExport>(StringComparer.OrdinalIgnoreCase);

        foreach (var export in package.Exports)
        {
            string className = package.GetClassName(export);
            if (className != AssetClasses.SkeletalMesh && className != AssetClasses.AnimationPackageWrapper) continue;

            string group = AssetContextResolver.TopLevelGroup(package, export);
            if (!group.StartsWith(WeaponGroupPrefix, StringComparison.OrdinalIgnoreCase)) continue;

            var target = className == AssetClasses.SkeletalMesh ? meshes : wrappers;
            if (!target.TryGetValue(group, out var existing) || export.SerialSize > existing.SerialSize)
                target[group] = export;
        }

        var result = new Dictionary<string, GroupAssets>(StringComparer.OrdinalIgnoreCase);
        foreach (var (group, mesh) in meshes)
        {
            result[group] = new GroupAssets(
                group, mesh.ObjectName, wrappers.TryGetValue(group, out var wrapper) ? wrapper.ObjectName : string.Empty);
        }

        return result;
    }

    /// <summary>
    /// Decides how strongly a candidate is attached, by checking whether its skeleton is rooted at
    /// the bone the socket names.
    /// </summary>
    private static (string Confidence, string Evidence) Assess(
        BioShockPackage package, GroupAssets candidate, MeshSocket socket)
    {
        string naming = $"the host's '{socket.Name}' socket is on bone '{socket.BoneName}', "
                        + $"and the group '{candidate.Group}' is named for that socket";

        if (candidate.Wrapper.Length == 0)
            return ("Likely", naming + "; it has no animation package, so its skeleton could not be checked");

        try
        {
            var wrapper = package.Exports
                .Where(e => e.ObjectName == candidate.Wrapper
                            && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
                .MaxBy(e => e.SerialSize);
            if (wrapper is null) return ("Likely", naming);

            var animations = AnimationPackage.Load(package, wrapper);
            var root = animations.Skeleton.Bones.FirstOrDefault(b => b.IsRoot);
            if (root is null) return ("Likely", naming);

            // Casing differs between the Havok tables and the Unreal objects (R_Grip / R_grip).
            if (string.Equals(root.Name, socket.BoneName, StringComparison.OrdinalIgnoreCase))
            {
                return ("Confirmed",
                    $"its skeleton is rooted at '{root.Name}', the bone the host's '{socket.Name}' socket "
                    + "attaches to — the game states this relationship rather than it being inferred");
            }

            return ("Likely", naming + $", but its skeleton is rooted at '{root.Name}' instead");
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return ("Likely", naming + "; its skeleton could not be read");
        }
    }

    /// <summary>
    /// Names the attachment animation that plays with a host animation.
    /// </summary>
    /// <remarks>
    /// <c>HEURISTIC</c>. The pistol's <c>FastReload</c> goes with the hands' <c>FastReloadPistol</c>,
    /// and the pairing that is actually proven is that their frame counts match exactly — but nothing
    /// in the data names the partner, so the longest shared prefix is used and short matches are
    /// rejected rather than guessed at.
    /// </remarks>
    public static string? Counterpart(string hostAnimation, IReadOnlyList<string> candidates)
    {
        string? best = null;
        int bestScore = 0;

        foreach (string candidate in candidates)
        {
            int score = 0;
            while (score < hostAnimation.Length && score < candidate.Length
                   && char.ToLowerInvariant(hostAnimation[score]) == char.ToLowerInvariant(candidate[score]))
            {
                score++;
            }
            if (score > bestScore) (best, bestScore) = (candidate, score);
        }

        return bestScore >= 4 ? best : null;
    }
}
