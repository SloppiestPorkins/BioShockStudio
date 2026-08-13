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
    string Evidence)
{
    /// <summary>
    /// True when the attachment is a static prop rather than a rig of its own — the Bouncer's drill
    /// rather than the first-person pistol. It has no skeleton and no animations, so it is placed on
    /// the host's socket bone and moves with it.
    /// </summary>
    public bool IsStatic { get; init; }
}

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

        // Kind two first: static props living in the host's own group. These need no second skeleton
        // and no second package, so they are resolved before the weapon sweep below.
        results.AddRange(StaticAttachments(host, sockets));

        // Weapon viewmodels are not in the map packages; they are in the script package.
        foreach (string packageName in catalog.Packages)
        {
            cancellation.ThrowIfCancellationRequested();

            using var package = BioShockPackage.Open(catalog.PackageFile(packageName));
            var groups = GroupsWithSkeletons(package);
            if (groups.Count == 0) continue;

            foreach (var socket in sockets)
            {
                if (BestGroupFor(socket.Name, groups) is not { } candidate) continue;

                var (confidence, evidence) = Assess(package, candidate, socket);

                results.Add(new AttachmentCandidate(
                    socket.Name, socket.BoneName, packageName, candidate.Group,
                    candidate.Mesh, candidate.Wrapper, confidence, evidence));
            }
        }

        return results
            .GroupBy(r => r.Socket, StringComparer.OrdinalIgnoreCase)
            .Select(g => g.OrderBy(Rank).First())
            .OrderBy(r => r.Socket, StringComparer.OrdinalIgnoreCase)
            .ToList();

        // A stated relationship beats a prop found in the host's own group, which in turn beats a
        // name that merely resembles a weapon group in some other package.
        static int Rank(AttachmentCandidate c) => c.Confidence == "Confirmed" ? 0 : c.IsStatic ? 1 : 2;
    }

    /// <summary>
    /// Static props a host's sockets name, found in the host's own group.
    /// </summary>
    /// <remarks>
    /// The second of the three kinds of thing a socket points at. <c>NewProtectorBouncer</c> declares
    /// <c>Drill</c>, <c>DrillCage</c> and <c>backpack</c>, and its own group holds <c>ConeDrill</c>,
    /// <c>ConeDrillCage</c> and <c>ConeDrillBackpack</c> — three static meshes, no second skeleton and
    /// no weapon group involved. The relationship is a name match within a group the game itself
    /// declares, so it is reported as <c>Likely</c>: strong, but not the explicit statement a
    /// skeleton rooted at the socket bone gives.
    /// </remarks>
    private IReadOnlyList<AttachmentCandidate> StaticAttachments(
        CatalogEntry host, IReadOnlyList<MeshSocket> sockets)
    {
        using var package = BioShockPackage.Open(catalog.PackageFile(host.Package));

        var props = package.Exports
            .Where(e => package.GetClassName(e) == AssetClasses.StaticMesh
                        && e.SerialSize > 0
                        && string.Equals(AssetContextResolver.TopLevelGroup(package, e), host.Group,
                            StringComparison.OrdinalIgnoreCase))
            .GroupBy(e => e.ObjectName, StringComparer.OrdinalIgnoreCase)
            .Select(g => g.MaxBy(e => e.SerialSize)!)
            .ToList();

        if (props.Count == 0) return [];

        var results = new List<AttachmentCandidate>();
        var taken = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        // Best match first, so 'Drill' claims ConeDrill before 'DrillCage' can, and no prop is
        // offered for two different sockets.
        foreach (var (socket, prop, rank) in sockets
                     .Select(s => (Socket: s, Match: BestByName(NormaliseSocket(s.Name), props, e => e.ObjectName)))
                     .Where(x => x.Match.Rank != NoMatch)
                     .Select(x => (x.Socket, Prop: x.Match.Value!, x.Match.Rank))
                     .OrderBy(x => x.Rank))
        {
            if (!taken.Add(prop.ObjectName)) continue;

            results.Add(new AttachmentCandidate(
                socket.Name, socket.BoneName, host.Package, host.Group,
                prop.ObjectName, string.Empty, "Likely",
                $"'{prop.ObjectName}' is a static mesh in the host's own group '{host.Group}', and its "
                + $"name matches the '{socket.Name}' socket, which sits on bone '{socket.BoneName}'")
            {
                IsStatic = true,
            });
        }

        return results;
    }

    private readonly record struct GroupAssets(string Group, string Mesh, string Wrapper);

    /// <summary>
    /// Finds the weapon group a socket names.
    /// </summary>
    /// <remarks>
    /// The game does not spell its sockets and its groups the same way. <c>Pistol</c> and
    /// <c>TommyGun</c> match <c>WP_Pistol</c> and <c>WP_TommyGun</c> exactly, but the hands' socket
    /// <c>Chem</c> belongs to <c>WP_ChemicalThrower</c> and <c>Launcher</c> to
    /// <c>WP_GrenadeLauncher</c>. Requiring an exact match found the pistol and left most of the
    /// arsenal looking unsupported when it was only unnamed.
    /// </remarks>
    private static GroupAssets? BestGroupFor(string socket, IReadOnlyDictionary<string, GroupAssets> groups)
    {
        var (value, rank) = BestByName(
            NormaliseSocket(socket),
            groups.Values,
            assets => assets.Group.StartsWith(WeaponGroupPrefix, StringComparison.OrdinalIgnoreCase)
                ? assets.Group[WeaponGroupPrefix.Length..]
                : assets.Group);

        // GroupAssets is a struct, so "no match" has to be read off the rank — a default value is
        // not null and would sail straight into Assess.
        return rank == NoMatch ? null : value;
    }

    /// <summary>Rank returned when nothing matched at all.</summary>
    private const int NoMatch = int.MaxValue;

    /// <summary>
    /// Picks the candidate whose name best matches <paramref name="wanted"/>, already normalised.
    /// </summary>
    /// <remarks>
    /// Exact beats a prefix beats a suffix beats a substring, so <c>Launcher</c> takes
    /// <c>GrenadeLauncher</c> rather than whichever candidate happened to be enumerated first, and
    /// <c>Drill</c> takes <c>ConeDrill</c> rather than <c>ConeDrillCage</c>.
    /// </remarks>
    private static (T? Value, int Rank) BestByName<T>(string wanted, IEnumerable<T> candidates, Func<T, string> nameOf)
    {
        if (wanted.Length < 4) return (default, NoMatch);

        T? best = default;
        int bestRank = NoMatch;

        foreach (var candidate in candidates)
        {
            string name = Normalise(nameOf(candidate));

            int rank = name == wanted ? 0
                : name.StartsWith(wanted, StringComparison.Ordinal) ? 1
                : name.EndsWith(wanted, StringComparison.Ordinal) ? 2
                : name.Contains(wanted, StringComparison.Ordinal) ? 3
                : wanted.Contains(name, StringComparison.Ordinal) && name.Length >= 4 ? 4
                : NoMatch;

            if (rank < bestRank) (best, bestRank) = (candidate, rank);
        }

        return bestRank == NoMatch ? (default, NoMatch) : (best, bestRank);
    }

    private static string Normalise(string value) =>
        new(value.Where(char.IsLetterOrDigit).Select(char.ToLowerInvariant).ToArray());

    /// <summary>Socket suffix the game appends on some hosts but never on the asset itself.</summary>
    private const string SocketNameSuffix = "socket";

    /// <summary>
    /// Normalises a socket name, dropping a trailing <c>Socket</c>.
    /// </summary>
    /// <remarks>
    /// <c>ProtectorRosie</c> declares <c>RivetGunSocket</c> and her weapon is the group
    /// <c>WP_AI_RivetGun</c>; <c>SecurityBot</c> and the turrets are the same shape. Leaving the
    /// suffix on made those look unsupported when they were only spelled differently. The stripped
    /// name still has to clear the four-character floor, so a socket named merely <c>Socket</c>
    /// matches nothing.
    /// </remarks>
    private static string NormaliseSocket(string socket)
    {
        string name = Normalise(socket);
        return name.Length > SocketNameSuffix.Length && name.EndsWith(SocketNameSuffix, StringComparison.Ordinal)
            ? name[..^SocketNameSuffix.Length]
            : name;
    }

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
