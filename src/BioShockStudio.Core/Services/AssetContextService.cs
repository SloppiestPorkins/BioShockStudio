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

    /// <summary>
    /// True when this is the weapon an NPC carries — a <c>WP_AI_*</c> static mesh — rather than the
    /// player's first-person viewmodel of the same weapon. The two are different assets, and a
    /// splicer used to be offered the player's.
    /// </summary>
    public bool IsNpcWeapon { get; init; }
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
        bool isFirstPerson = host.Group.Contains("PlayerHands", StringComparison.OrdinalIgnoreCase);

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

        // Kind four: the weapon an NPC carries, which is a different asset from the one the player
        // holds. Resolved before the viewmodel sweep so a splicer is not handed the first-person
        // pistol.
        results.AddRange(NpcWeaponAttachments(host, sockets, cancellation));

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

                // A weapon group carrying its own rig is a first-person viewmodel — the thing in the
                // player's hands. Offering one to an NPC on a name match alone is how a splicer came
                // to be handed WP_GrenadeLauncherMesh: there is no WP_AI_GrenadeLauncher, so the
                // socket fell through to the player's. A stated relationship still counts for
                // anyone — if the weapon's skeleton is rooted at the host's socket bone, that is
                // evidence rather than a resemblance — but a resemblance alone is not enough.
                if (confidence != "Confirmed" && !isFirstPerson) continue;

                results.Add(new AttachmentCandidate(
                    socket.Name, socket.BoneName, packageName, candidate.Group,
                    candidate.Mesh, candidate.Wrapper, confidence, evidence));
            }
        }

        // Kind five: a weapon the host has animations for but no socket named after. Only the
        // first-person rig, and only on the host's own animation sets — see WeaponsNamedByAnAnimationSet.
        if (isFirstPerson) results.AddRange(WeaponsNamedByAnAnimationSet(host, sockets, results, cancellation));

        return results
            .GroupBy(r => r.Socket, StringComparer.OrdinalIgnoreCase)
            .Select(g => g.OrderBy(Rank).First())
            .OrderBy(r => r.Socket, StringComparer.OrdinalIgnoreCase)
            .ToList();

        // A stated relationship beats a prop found in the host's own group, which beats the NPC
        // weapon whose name the socket carries, which beats a name that merely resembles a weapon
        // group in some other package. The NPC weapon outranks the viewmodel deliberately: both are
        // matched by name, and only one of them is the thing this host actually holds.
        static int Rank(AttachmentCandidate c) =>
            c.Confidence == "Confirmed" ? 0
            : c.IsNpcWeapon ? 1
            : c.IsStatic ? 2
            : 3;
    }

    /// <summary>
    /// A weapon the host has an animation set for but declares no socket for.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>This exists for the shotgun, and the shotgun is the only asset in the game that needs it.</b>
    /// It is one of the seven weapons the player carries, and every other route to it is absent:
    /// </para>
    /// <list type="bullet">
    /// <item><c>NEWPlayerHands</c> declares <b>no <c>Shotgun</c> socket</b> — measured on all twenty
    /// shipped copies of the mesh, which carry an identical table of 19.</item>
    /// <item><c>WP_Shotgun</c>'s rig is rooted at <b><c>SG_Body</c></b>, not <c>R_grip</c>: its three
    /// bones are <c>SG_Body, SG_Pump, SG_Shell</c>. Every other weapon is rooted at <c>R_grip</c> and
    /// is promoted to <c>Confirmed</c> by that name matching the socket's bone. The shotgun cannot
    /// be, so it was offered nowhere and six of the seven weapons worked.</item>
    /// </list>
    /// <para>
    /// <b>What is stated, and what is inferred.</b> The link itself is stated by the game: the hands
    /// carry a <c>Shotgun</c> animation set of their own
    /// (<c>USharedSkeletonAnimationMetadata_EmptyFidgetShotgun</c> and its siblings), and
    /// <c>WP_Shotgun</c> is the only shotgun viewmodel. What is <i>inferred</i> is the attach point:
    /// every weapon socket on this rig sits on <c>R_grip</c>, so that is where this puts it. So the
    /// candidate is <c>Likely</c> and its evidence says which half is which. It is never
    /// <c>Confirmed</c> — that word is reserved for the root-bone match this weapon cannot satisfy.
    /// </para>
    /// <para>
    /// <b>Deliberately narrow.</b> First-person hosts only, weapon groups only, and only where the
    /// host's own animation sets name the weapon — so it cannot hand an NPC a viewmodel, which is the
    /// decision this project made after every splicer was offered the player's pistol.
    /// </para>
    /// </remarks>
    private IReadOnlyList<AttachmentCandidate> WeaponsNamedByAnAnimationSet(
        CatalogEntry host,
        IReadOnlyList<MeshSocket> sockets,
        IReadOnlyList<AttachmentCandidate> already,
        CancellationToken cancellation)
    {
        // The bone every weapon socket on this rig uses. Without one there is nowhere to infer.
        string? weaponBone = sockets
            .GroupBy(s => s.BoneName, StringComparer.OrdinalIgnoreCase)
            .OrderByDescending(g => g.Count())
            .FirstOrDefault()
            ?.Key;

        if (weaponBone is null) return [];

        IReadOnlyList<string> owners;
        try { owners = HostAnimationSets(host); }
        catch (Exception ex) when (ex is InvalidDataException or IOException) { return []; }

        if (owners.Count == 0) return [];

        var results = new List<AttachmentCandidate>();

        foreach (string packageName in catalog.Packages)
        {
            cancellation.ThrowIfCancellationRequested();

            using var package = BioShockPackage.Open(catalog.PackageFile(packageName));
            var groups = GroupsWithSkeletons(package);
            if (groups.Count == 0) continue;

            foreach (string owner in owners)
            {
                // A set already served by a socket is not this method's business.
                if (already.Any(a => string.Equals(AnimationSetFor(a, owners), owner, StringComparison.OrdinalIgnoreCase)))
                    continue;

                if (results.Any(r => string.Equals(r.Socket, owner, StringComparison.OrdinalIgnoreCase))) continue;
                if (sockets.Any(s => string.Equals(NormaliseSocket(s.Name), Normalise(owner), StringComparison.Ordinal)))
                    continue;

                if (BestGroupFor(owner, groups) is not { } candidate) continue;

                results.Add(new AttachmentCandidate(
                    owner, weaponBone, packageName, candidate.Group,
                    candidate.Mesh, candidate.Wrapper, "Likely",
                    $"the hands carry a '{owner}' animation set of their own and '{candidate.Group}' is "
                    + $"the weapon of that name, but this rig declares no '{owner}' socket and the "
                    + $"weapon's skeleton is not rooted at '{weaponBone}', so the link is stated by "
                    + $"the animation set while the attach point is inferred from where this rig's "
                    + "other weapons attach"));
            }
        }

        return results;
    }

    /// <summary>The animation sets a host's own animation package declares.</summary>
    private IReadOnlyList<string> HostAnimationSets(CatalogEntry host)
    {
        using var package = BioShockPackage.Open(catalog.PackageFile(host.Package));

        var wrapper = package.Exports
            .Where(e => package.GetClassName(e) == AssetClasses.AnimationPackageWrapper
                        && string.Equals(AssetContextResolver.TopLevelGroup(package, e), host.Group,
                            StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);

        if (wrapper is null) return [];

        return AnimationPackage.Load(package, wrapper).Owners
            .Where(o => o.Length > 0)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    /// <summary>Group prefix for the weapon an NPC carries, as opposed to the player's viewmodel.</summary>
    /// <remarks>
    /// <c>CONFIRMED_BYTES</c>, and already recorded in <c>docs/research/firstperson.md</c>:
    /// <c>WP_AI_Pistol</c> is a <c>StaticMesh</c>, and the <c>WP_AI_</c> prefix together with that
    /// class marks the NPC-carried weapon — a different asset from whatever the first-person pistol
    /// uses. The game ships twelve: pistol, smg, wrench, pipe, machete, rake, shovel, rivet gun,
    /// grenade box, molotov box, flashlight and handcart.
    /// </remarks>
    private const string NpcWeaponPrefix = "WP_AI_";

    /// <summary>
    /// The NPC weapons a host's sockets name.
    /// </summary>
    /// <remarks>
    /// Without this a splicer was offered the player's first-person viewmodels, because those are
    /// the only weapon groups that carry a skeleton and the viewmodel sweep only looks at groups
    /// that do. A splicer's <c>Pistol</c> socket resolved to <c>WP_Pistol</c> — the thing in the
    /// player's hands — and its <c>smg</c> and <c>MeleePipe</c> sockets resolved to nothing at all.
    /// <para>
    /// The match is by name and is reported as <c>Likely</c>, never <c>Confirmed</c>: a static mesh
    /// has no root bone to check the socket against, so there is no stated relationship to promote
    /// it on. A socket the game fills at runtime from a set — <c>Melee</c>, which could be any of
    /// the wrench, pipe, machete, rake or shovel — matches none of them exactly and is deliberately
    /// left unresolved rather than being given whichever sorted first.
    /// </para>
    /// </remarks>
    private IReadOnlyList<AttachmentCandidate> NpcWeaponAttachments(
        CatalogEntry host, IReadOnlyList<MeshSocket> sockets, CancellationToken cancellation)
    {
        // The player's own hands hold viewmodels, not the NPC props.
        if (host.Group.Contains("PlayerHands", StringComparison.OrdinalIgnoreCase)) return [];

        var results = new List<AttachmentCandidate>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (string packageName in catalog.Packages)
        {
            cancellation.ThrowIfCancellationRequested();

            using var package = BioShockPackage.Open(catalog.PackageFile(packageName));
            var weapons = package.Exports
                .Where(e => package.GetClassName(e) == AssetClasses.StaticMesh
                            && e.SerialSize > 0
                            && e.ObjectName.StartsWith(NpcWeaponPrefix, StringComparison.OrdinalIgnoreCase))
                .GroupBy(e => e.ObjectName, StringComparer.OrdinalIgnoreCase)
                .Select(g => g.MaxBy(e => e.SerialSize)!)
                .ToList();

            if (weapons.Count == 0) continue;

            foreach (var socket in sockets)
            {
                // Exact name only. These are twelve short names in one flat set, so the fuzzy match
                // the viewmodel sweep needs would happily give 'Melee' the machete.
                var weapon = weapons.FirstOrDefault(e => string.Equals(
                    e.ObjectName[NpcWeaponPrefix.Length..], NormaliseSocket(socket.Name),
                    StringComparison.OrdinalIgnoreCase));
                if (weapon is null || !seen.Add(socket.Name)) continue;

                results.Add(new AttachmentCandidate(
                    socket.Name, socket.BoneName, packageName, weapon.ObjectName,
                    weapon.ObjectName, string.Empty, "Likely",
                    $"'{weapon.ObjectName}' is a static mesh whose name after the '{NpcWeaponPrefix}' "
                    + $"prefix is exactly the '{socket.Name}' socket, which sits on bone "
                    + $"'{socket.BoneName}'. That prefix and class mark the weapon an NPC carries, "
                    + "which is a different asset from the player's viewmodel")
                {
                    IsStatic = true,
                    IsNpcWeapon = true,
                });
            }
        }

        return results;
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
    /// The host animation set that belongs to an attachment.
    /// </summary>
    /// <remarks>
    /// The hands carry 130 animations in sets named after the weapons — <c>Pistol</c>,
    /// <c>GrenadeLauncher</c>, <c>Crossbow</c>, <c>ChemicalThrower</c> — and playing one weapon's
    /// set while another is attached poses the hands for a gun that is not there. It looks exactly
    /// like a broken attachment: the launcher passes through the forearm and neither hand is on it.
    /// <para>
    /// Matched on the attachment's group first, since <c>WP_GrenadeLauncher</c> names the set
    /// exactly, and on the socket name second — the socket is <c>Launcher</c> where the set is
    /// <c>GrenadeLauncher</c>.
    /// </para>
    /// </remarks>
    public static string? AnimationSetFor(AttachmentCandidate attachment, IReadOnlyList<string> sets)
    {
        if (sets.Count == 0) return null;

        string group = attachment.Group.StartsWith(WeaponGroupPrefix, StringComparison.OrdinalIgnoreCase)
            ? attachment.Group[WeaponGroupPrefix.Length..]
            : attachment.Group;

        var (byGroup, groupRank) = BestByName(Normalise(group), sets, s => s);
        if (groupRank != NoMatch) return byGroup;

        var (bySocket, socketRank) = BestByName(NormaliseSocket(attachment.Socket), sets, s => s);
        return socketRank == NoMatch ? null : bySocket;
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
    /// <summary>
    /// The attachment animation that plays with a host animation, matching on length first.
    /// </summary>
    /// <remarks>
    /// A first-person animation is one performance on two rigs, so the partner has exactly as many
    /// frames. That is the evidence; the name is only a tie-break among candidates that already
    /// agree on length.
    /// <para>
    /// Name alone gets it wrong. The hands' <c>FireLauncher</c> shares six characters with the
    /// weapon's <c>FireLast</c> and only four with its <c>Fire</c>, so the longest-prefix rule
    /// picks the two-frame <c>FireLast</c> over the forty-four-frame <c>Fire</c> that actually
    /// belongs to it — and the weapon then sits in its rest pose while the hands perform, which
    /// looks exactly like a broken attachment.
    /// </para>
    /// </remarks>
    public static string? Counterpart(
        string hostAnimation, int hostFrameCount, IReadOnlyList<AnimationSetEntry> candidates)
    {
        var sameLength = candidates
            .Where(c => c.FrameCount == hostFrameCount)
            .Select(c => c.Name)
            .ToList();

        return sameLength.Count == 0 ? null : Counterpart(hostAnimation, sameLength);
    }

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
