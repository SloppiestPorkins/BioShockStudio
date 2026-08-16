using System.Numerics;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Which way a first-person weapon points once it is placed on the hands' socket.
/// </summary>
/// <remarks>
/// <para>
/// Reported by the user, 16 Aug 2026: "all guns in the NEWPlayerHands animations are backwards".
/// This measures it rather than judging it from a render, for the reason
/// <c>SocketOrientationTests</c> gives about props and the reason <c>docs/HANDOFF.md</c> §4 gives
/// about the first-person rig: <b>the rig's own space is not world space</b>, so screen left/right
/// and screen forward mean nothing here, and a render can be read either way by someone who expects
/// a particular answer.
/// </para>
/// <para>
/// <b>The metric.</b> A viewmodel is held in front of the player and points away from them. The rig
/// root sits at the player, the socket bone sits at the grip, so <c>grip - root</c> is the direction
/// the arms reach — that is "forward" without needing to know the rig's axes. A correctly placed
/// weapon then has its far end (muzzle, prod, nozzle) <i>further along that direction</i> than its
/// grip end. A backwards weapon has it behind, pointing back at the player.
/// </para>
/// <para>
/// This is deliberately the same shape of argument as the hand-side metric that settled the Phase 1
/// blocker: an axis taken from bones that are <i>not</i> the thing being judged. The weapon's own
/// geometry decides nothing about which way is forward; the arm does.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class FirstPersonWeaponOrientationTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>One weapon's placement, measured along the arm's own reach direction.</summary>
    private readonly record struct Placement(
        string Socket,
        string Mesh,
        float GripAhead,
        float TipAhead,
        float CentreAhead,
        float Span)
    {
        /// <summary>
        /// How far the weapon's far end sits ahead of its grip end, along the reach direction.
        /// Positive is a weapon pointing away from the player; negative is one pointing back at them.
        /// </summary>
        public float Reach => TipAhead - GripAhead;

        public bool PointsForward => Reach > 0f;
    }

    /// <summary>
    /// The animation to judge each weapon in, and why it must not be the rest pose.
    /// </summary>
    /// <remarks>
    /// <b>The first version of this measured the bind pose and was wrong to.</b> A viewmodel's rest
    /// pose has the arms hanging with the fingers open and nothing gripped, so the weapon sits beside
    /// the forearm because no hand is holding it — which measures as "backwards" on data that may be
    /// perfectly correct. It is the animation that poses the hand onto the weapon, and the animation
    /// is what was reported. Rendered and looked at before this was changed; see
    /// <see cref="Render_WeaponsOnTheHands"/>.
    /// </remarks>
    private static string? IdleFor(IReadOnlyList<AnimationSetEntry> sets, string? animationSet)
    {
        var candidates = sets
            .Where(s => animationSet is null
                        || string.Equals(s.Owner, animationSet, StringComparison.OrdinalIgnoreCase))
            .ToList();

        if (candidates.Count == 0) return null;

        // An idle holds the weapon in its carried position for the whole clip, which is the pose the
        // question is actually about. A fire or reload moves the weapon through the hand on purpose.
        return (candidates.FirstOrDefault(s => s.Name.Contains("idle", StringComparison.OrdinalIgnoreCase))
                is { Name: { Length: > 0 } idle } ? idle
                : candidates.FirstOrDefault(s => s.Name.Contains("fidget", StringComparison.OrdinalIgnoreCase)) is
                    { Name: { Length: > 0 } fidget } ? fidget
                : candidates[0].Name);
    }

    private List<Placement> Measure()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = Core.Packages.BioShockPackage.Open(game.LighthousePackage);
        var entry = AssetCatalogService.Catalogue(package, "0-Lighthouse")
            .Single(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);

        var preview = new MeshPreviewService(catalog);
        var subject = preview.Load(entry);
        var host = subject.Model;

        int rootBone = 0;
        for (int i = 0; i < host.Bones.Count; i++)
            if (host.Bones[i].Parent < 0) rootBone = i;

        var results = new List<Placement>();
        var owners = subject.AnimationSets.Select(s => s.Owner).Distinct(StringComparer.OrdinalIgnoreCase).ToList();

        Log($"=== NEWPlayerHands: {host.Bones.Count} bones, root '{host.Bones[rootBone].Name}'");

        // Every socket the rig declares, with what it carries. The point of interest is how many of
        // them share one bone: the placement code picks a socket by BONE, so if several sit on the
        // same bone it gets whichever was read first regardless of which weapon is attached.
        foreach (var s in host.Sockets.OrderBy(s => s.Bone))
        {
            var q = Quaternion.CreateFromRotationMatrix(s.Transform);
            float deg = 2f * MathF.Acos(Math.Clamp(MathF.Abs(q.W), -1f, 1f)) * 180f / MathF.PI;
            Log($"    socket {s.Name,-22} on bone {host.Bones[s.Bone].Name,-18} "
                + $"offset {Fmt(s.Transform.Translation)} rotation {deg,6:0.#} deg about ({q.X:0.##},{q.Y:0.##},{q.Z:0.##})");
        }

        foreach (var attachment in new AssetContextService(catalog).Attachments(entry)
                     .Where(a => !a.IsStatic))
        {
            int bone = -1;
            for (int i = 0; i < host.Bones.Count; i++)
                if (string.Equals(host.Bones[i].Name, attachment.SocketBone, StringComparison.OrdinalIgnoreCase))
                    bone = i;

            if (bone < 0) { Log($"  {attachment.Socket}: bone '{attachment.SocketBone}' not on the rig"); continue; }

            var weapon = preview.LoadAttachment(attachment).Model;
            if (!weapon.HasGeometry) { Log($"  {attachment.Socket}: no geometry"); continue; }

            // Judge it in the pose the hand actually holds the weapon in, not the bind pose. See
            // IdleFor: the rest pose has the fingers open and grips nothing, and measuring it says
            // "backwards" about data that may be right.
            string? set = AssetContextService.AnimationSetFor(attachment, owners);
            string? clip = IdleFor(subject.AnimationSets, set);
            var animation = clip is null ? null : preview.LoadAnimation(entry, clip);

            if (animation is null)
            {
                Log($"  {attachment.Socket}: no animation resolved (set '{set}', clip '{clip}') — skipped, "
                    + "because the rest pose cannot answer this");
                continue;
            }

            // Mid-clip: an idle's first frame is often still the authoring pose.
            int frame = animation.FrameCount / 2;
            var pose = host.Pose(animation.Decoded, frame);
            var root = pose[rootBone].Translation;

            Log($"  {attachment.Socket,-12} in '{clip}' (set '{set}') frame {frame} of {animation.FrameCount}");

            // Exactly the placement the viewport uses, so this measures what is drawn rather than a
            // second interpretation of it.
            var socket = host.Sockets.FirstOrDefault(s =>
                string.Equals(s.Name, attachment.Socket, StringComparison.OrdinalIgnoreCase));
            var boneMatrix = pose[bone];
            var transform = socket is null ? boneMatrix : socket.On(boneMatrix);

            // What the weapon's own rig says about where its root sits. The attachment is drawn by
            // multiplying weapon-skeleton space by the host's socket matrix, which is only correct
            // if the weapon's root bone frame IS the grip frame. If its reference transform is not
            // identity, the difference is applied to every vertex and nobody has checked it.
            int weaponRoot = -1;
            for (int i = 0; i < weapon.Bones.Count; i++)
                if (weapon.Bones[i].Parent < 0) weaponRoot = i;

            if (weaponRoot >= 0)
            {
                var rest = weapon.Bones[weaponRoot].RestGlobal;
                var q = Quaternion.CreateFromRotationMatrix(rest);
                float degrees = 2f * MathF.Acos(Math.Clamp(MathF.Abs(q.W), -1f, 1f)) * 180f / MathF.PI;
                Log($"      weapon root '{weapon.Bones[weaponRoot].Name}' rest {Fmt(rest.Translation)}"
                    + $"  rotation {degrees:0.#} deg about ({q.X:0.##},{q.Y:0.##},{q.Z:0.##})");
            }

            // Is the weapon drawn mirrored? A reflected placement produces a left-handed revolver:
            // every count agrees, every vertex is present, and it reads as "wrong way round" without
            // being rotated at all. The basis conversion is a reflection, so this is the one failure
            // mode that could plausibly come from it, and it is decided by a sign rather than by
            // looking. det > 0 is a rotation; det < 0 has a reflection in it.
            float det = transform.GetDeterminant();
            Log($"      placement determinant {det:0.####}  => {(det < 0 ? "MIRRORED" : "not mirrored")}");

            // What the socket itself contributes. The handoff records that every first-person weapon
            // socket has a zero ORIGIN, and that has been read ever since as "these sockets are
            // identity" — but origin and rotation are different fields, and 246 of the game's 332
            // sockets carry a rotation. If one of these carries a rotation and it is being applied in
            // the wrong direction, the error is that rotation squared: a 90 degree socket applied
            // inverted lands 180 degrees out, which is exactly the reported symptom.
            if (socket is not null)
            {
                var sq = Quaternion.CreateFromRotationMatrix(socket.Transform);
                float sdeg = 2f * MathF.Acos(Math.Clamp(MathF.Abs(sq.W), -1f, 1f)) * 180f / MathF.PI;
                Log($"      socket '{socket.Name}' offset {Fmt(socket.Transform.Translation)}"
                    + $"  rotation {sdeg:0.#} deg about ({sq.X:0.##},{sq.Y:0.##},{sq.Z:0.##})"
                    + $"  identity={socket.Transform.IsIdentity}");
            }
            else
            {
                Log("      socket: none on this bone — placed on the bone frame alone");
            }

            // THE REPORTED SYMPTOM, measured directly: "the pistol is looking at the player camera".
            //
            // This is not the same question as "does the weapon extend away from the player", which
            // is what the reach figure below measures and which passed on five of six. A weapon can
            // sit out in front of the player and still be turned round to face them. What decides it
            // is the direction from the grip to the muzzle against the direction the player is
            // looking — the muzzle being the point of the mesh furthest from the socket, which for
            // every weapon here is the end of the barrel.
            {
                var eyeAt = pose[rootBone].Translation;

                var middle = Vector3.Zero;
                foreach (var v in weapon.Vertices) middle += Vector3.Transform(v.Position, transform);
                middle /= Math.Max(1, weapon.Vertices.Count);

                var gripAt = transform.Translation;
                var muzzle = gripAt;
                float furthest = -1f;

                foreach (var v in weapon.Vertices)
                {
                    var world = Vector3.Transform(v.Position, transform);
                    float d = Vector3.DistanceSquared(world, gripAt);
                    if (d > furthest) { furthest = d; muzzle = world; }
                }

                var view = middle - eyeAt;
                var barrel = muzzle - gripAt;

                if (view.LengthSquared() > 1e-6f && barrel.LengthSquared() > 1e-6f)
                {
                    float facing = Vector3.Dot(Vector3.Normalize(barrel), Vector3.Normalize(view));
                    Log($"      barrel vs view: dot {facing,6:0.###}  "
                        + $"({MathF.Acos(Math.Clamp(facing, -1f, 1f)) * 180f / MathF.PI:0.#} deg)  => "
                        + (facing < 0f ? "MUZZLE POINTS AT THE PLAYER" : "muzzle points away"));
                }
            }

            var grip = transform.Translation;
            var forward = grip - root;
            if (forward.LengthSquared() < 1e-6f) { Log($"  {attachment.Socket}: grip sits on the root"); continue; }
            forward = Vector3.Normalize(forward);

            // Where the weapon's own extremes land, projected on the arm's reach direction.
            float lo = float.MaxValue, hi = float.MinValue;
            var centroid = Vector3.Zero;

            foreach (var v in weapon.Vertices)
            {
                var world = Vector3.Transform(v.Position, transform);
                float along = Vector3.Dot(world - root, forward);
                lo = MathF.Min(lo, along);
                hi = MathF.Max(hi, along);
                centroid += world;
            }

            centroid /= Math.Max(1, weapon.Vertices.Count);

            // A second, independent axis: the forearm's own pointing direction, elbow to hand. It
            // shares no bone with the reach axis above except the hand, and it does not involve the
            // root at all — so if the two disagree, neither is trusted. This project has twice
            // adopted a metric that read green on broken data (§4), and the defence both times was a
            // second measurement built from different bones.
            var forearm = BoneNamed(host, "Bip01_R_Forearm");
            var hand = BoneNamed(host, "Bip01_R_Hand");
            float alongArm = float.NaN;

            if (forearm >= 0 && hand >= 0)
            {
                var armAxis = pose[hand].Translation - pose[forearm].Translation;

                if (armAxis.LengthSquared() > 1e-6f)
                {
                    armAxis = Vector3.Normalize(armAxis);
                    float armLo = float.MaxValue, armHi = float.MinValue;

                    foreach (var v in weapon.Vertices)
                    {
                        float a = Vector3.Dot(Vector3.Transform(v.Position, transform) - grip, armAxis);
                        armLo = MathF.Min(armLo, a);
                        armHi = MathF.Max(armHi, a);
                    }

                    // Positive means the weapon's bulk continues past the hand, the way a held
                    // weapon does; negative means it runs back down the forearm.
                    alongArm = MathF.Abs(armHi) >= MathF.Abs(armLo) ? armHi : armLo;
                    Log($"      forearm axis: weapon spans {armLo,8:0.#} .. {armHi,8:0.#} past the grip"
                        + $"  => {(alongArm > 0 ? "FORWARD" : "BACKWARDS")} along the arm");
                }
            }

            float gripAhead = Vector3.Dot(grip - root, forward);

            // The grip end is whichever extreme is nearer the hand; the far end is the other one.
            bool loIsGrip = MathF.Abs(lo - gripAhead) <= MathF.Abs(hi - gripAhead);
            float gripEnd = loIsGrip ? lo : hi;
            float tipEnd = loIsGrip ? hi : lo;

            var placement = new Placement(
                attachment.Socket, attachment.MeshObject,
                gripEnd, tipEnd, Vector3.Dot(centroid - root, forward), hi - lo);

            results.Add(placement);

            Log($"  {placement.Socket,-12} {placement.Mesh,-24} {weapon.Vertices.Count,6} verts");
            Log($"      grip {gripAhead,8:0.#} ahead of root   weapon spans {lo,8:0.#} .. {hi,8:0.#}  ({placement.Span:0.#} long)");
            Log($"      grip end {placement.GripAhead,8:0.#}   far end {placement.TipAhead,8:0.#}   centre {placement.CentreAhead,8:0.#}");
            Log($"      => reach {placement.Reach,8:0.#}  {(placement.PointsForward ? "FORWARD (correct)" : "BACKWARDS")}");
        }

        return results;
    }

    /// <summary>
    /// An attachment is placed on the socket it names, not on whichever socket shares its bone.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>This is the assertion that pins the fault, and it is deliberately structural rather than
    /// geometric.</b> Two direction metrics were written for this first — the weapon's extent along
    /// the arm's reach, and its barrel against the view direction — and <b>both read green on the
    /// broken pistol</b>. The reach metric passed it at +19 because the reach axis on this rig runs
    /// largely up the spine, so a barrel pointing back and up still scored positive; the barrel
    /// metric passed it at +0.24 because "the direction from the eye to the weapon" is not the
    /// direction the player looks. A metric that cannot fail on the very data that provoked it is
    /// worth nothing, and this project has recorded that lesson twice already (§4, and the two
    /// discarded hand-side metrics).
    /// </para>
    /// <para>
    /// What was actually wrong is exact and has no tolerance in it: nine of the hands' sockets sit
    /// on the bone <c>R_grip</c>, the placement picked one by <i>bone</i>, and so every weapon got
    /// <c>Wrench</c> — which carries a 180 degree turn about Z where <c>Pistol</c> and <c>Chem</c>
    /// carry identity. So the check is that each attachment resolves its own socket, plus the
    /// consequence that made it visible: the pistol's placement must be its bone frame exactly,
    /// because the pistol's socket is identity.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void EachWeaponIsPlacedOnTheSocketItNames()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = Core.Packages.BioShockPackage.Open(game.LighthousePackage);
        var entry = AssetCatalogService.Catalogue(package, "0-Lighthouse")
            .Single(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);

        var host = new MeshPreviewService(catalog).Load(entry).Model;
        var weapons = new AssetContextService(catalog).Attachments(entry).Where(a => !a.IsStatic).ToList();

        Assert.True(weapons.Count >= 4,
            $"only {weapons.Count} weapons resolved, so this says nothing about 'all guns'");

        // The hazard has to exist for this test to mean anything: if the rig ever stopped sharing a
        // bone between sockets, picking by bone would silently become correct and this would pass
        // vacuously.
        var shared = host.Sockets
            .GroupBy(s => s.Bone)
            .Where(g => g.Count() > 1)
            .ToList();

        Assert.True(shared.Count > 0,
            "no bone on this rig carries more than one socket, so this test cannot detect the fault "
            + "it exists for — picking a socket by bone would be unambiguous");

        foreach (var attachment in weapons)
        {
            var named = host.Sockets.FirstOrDefault(s =>
                string.Equals(s.Name, attachment.Socket, StringComparison.OrdinalIgnoreCase));

            Assert.True(named is not null,
                $"'{attachment.Socket}' names no socket on the rig, so the attachment cannot be "
                + "placed on the transform the game gives it");

            // What picking by bone would have produced. Same expression the viewport used to use.
            var byBone = host.Sockets.FirstOrDefault(s => s.Bone == named!.Bone);

            Assert.True(byBone is not null);

            if (!string.Equals(byBone!.Name, named!.Name, StringComparison.OrdinalIgnoreCase))
            {
                // The two differ, which is exactly the trap. Assert the transforms are not silently
                // interchangeable, so nobody "simplifies" the lookup back to the bone later.
                Assert.False(byBone.Transform == named.Transform,
                    $"'{attachment.Socket}' and '{byBone.Name}' share bone "
                    + $"'{host.Bones[named.Bone].Name}' and happen to carry the same transform, so "
                    + "this case no longer demonstrates the fault — pick another weapon");
            }
        }

        // The consequence that was visible on screen, asserted through the shared placement rule so
        // this fails if that rule ever goes back to picking by bone. The pistol's socket is identity,
        // so its placement IS its bone frame; the old lookup returned the wrench's 180 degrees and
        // the revolver pointed back over the forearm at the player.
        var pistol = host.Sockets.Single(s => string.Equals(s.Name, "Pistol", StringComparison.OrdinalIgnoreCase));
        var wrench = host.Sockets.Single(s => string.Equals(s.Name, "Wrench", StringComparison.OrdinalIgnoreCase));

        Assert.True(pistol.Transform.IsIdentity,
            $"the Pistol socket is no longer identity ({pistol.Transform}) — this test's reasoning "
            + "about what the wrench's flip did to it needs rechecking");

        Assert.False(wrench.Transform.IsIdentity,
            "the Wrench socket is identity, so it can no longer be the source of the 180 degree flip "
            + "this test was written for");

        Assert.Equal(pistol.Bone, wrench.Bone);

        var boneFrame = host.Bones[pistol.Bone].RestGlobal;
        var placed = host.PlacementFor("Pistol", pistol.Bone);

        Assert.True(placed == boneFrame,
            "the pistol is not being placed on its own socket. Its socket is identity, so its "
            + $"placement must be the bone frame exactly.{Environment.NewLine}"
            + $"  bone frame : {boneFrame}{Environment.NewLine}"
            + $"  placed at  : {placed}{Environment.NewLine}"
            + $"  the wrench would give: {wrench.On(boneFrame)}{Environment.NewLine}"
            + "If 'placed at' matches the wrench, the placement rule is choosing a socket by bone "
            + "again and every first-person weapon is drawn backwards.");

        // And the two really are distinguishable, so the assertion above cannot pass by coincidence.
        Assert.False(wrench.On(boneFrame) == boneFrame);
    }

    /// <summary>
    /// Draws each weapon on the hands, with the skeleton, so the measurement above can be checked
    /// against a picture.
    /// </summary>
    /// <remarks>
    /// The measurement and the render disagreed at first — the numbers said every weapon was
    /// backwards while an orbit of the crossbow looked plausible — and this exists to settle that
    /// rather than to pick whichever answer was preferred. The skeleton overlay is the point: without
    /// it there is nothing in frame to say which way the arm runs, and "backwards" is unjudgeable.
    /// </remarks>
    [RequiresGameFact]
    public void Render_WeaponsOnTheHands()
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_WEAPON_SNAPSHOT") is not { Length: > 0 } target) return;

        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = Core.Packages.BioShockPackage.Open(game.LighthousePackage);
        var entry = AssetCatalogService.Catalogue(package, "0-Lighthouse")
            .Single(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);

        var preview = new MeshPreviewService(catalog);
        var subject = preview.Load(entry);
        var host = subject.Model;
        var owners = subject.AnimationSets.Select(s => s.Owner).Distinct(StringComparer.OrdinalIgnoreCase).ToList();

        foreach (var attachment in new AssetContextService(catalog).Attachments(entry).Where(a => !a.IsStatic))
        {
            int bone = -1;
            for (int i = 0; i < host.Bones.Count; i++)
                if (string.Equals(host.Bones[i].Name, attachment.SocketBone, StringComparison.OrdinalIgnoreCase))
                    bone = i;
            if (bone < 0) continue;

            var weapon = preview.LoadAttachment(attachment).Model;
            if (!weapon.HasGeometry) continue;

            // Posed, not at rest: at rest the fingers are open and nothing is held, so a render of it
            // says nothing about whether the weapon is the right way round.
            string? set = AssetContextService.AnimationSetFor(attachment, owners);
            string? clip = IdleFor(subject.AnimationSets, set);
            var animation = clip is null ? null : preview.LoadAnimation(entry, clip);
            var pose = animation is null ? null : host.Pose(animation.Decoded, animation.FrameCount / 2);

            var socket = host.Sockets.FirstOrDefault(s =>
                string.Equals(s.Name, attachment.Socket, StringComparison.OrdinalIgnoreCase));
            var boneMatrix = pose is null ? host.Bones[bone].RestGlobal : pose[bone];
            var transform = socket is null ? boneMatrix : socket.On(boneMatrix);

            var instances = new List<PreviewInstance>
            {
                new(host, pose),
                new(weapon, null, transform),
            };

            const int cell = 420, columns = 4;
            var sheet = new byte[columns * cell * cell * 4];
            var (centre, radius) = pose is null
                ? (host.Centre, host.Radius)
                : host.BoundsOver([pose]);

            // The first panel is the player's own view: eye at the rig root, looking at the weapon.
            // This is the only view that can answer "is it pointing at me", which is what was
            // reported — an orbit cannot, because nothing in an orbit frame says which way is
            // forward. The remaining three orbit it for context.
            var eye = pose is null ? host.Bones[0].RestGlobal.Translation : pose[0].Translation;
            var weaponCentre = Vector3.Zero;
            foreach (var v in weapon.Vertices) weaponCentre += Vector3.Transform(v.Position, transform);
            weaponCentre /= Math.Max(1, weapon.Vertices.Count);

            for (int i = 0; i < columns; i++)
            {
                PreviewCamera camera;

                if (i == 0)
                {
                    var toWeapon = weaponCentre - eye;
                    var dir = Vector3.Normalize(-toWeapon);
                    camera = new PreviewCamera
                    {
                        Target = weaponCentre,
                        Distance = MathF.Max(toWeapon.Length(), 1f),
                        Pitch = MathF.Asin(Math.Clamp(dir.Z, -1f, 1f)),
                        Yaw = MathF.Atan2(dir.Y, dir.X),
                        FieldOfView = 75f * MathF.PI / 180f,
                    };
                }
                else
                {
                    camera = PreviewCamera.Frame(centre, radius * 1.25f)
                        .Orbit(i * MathF.PI * 0.5f, 0.15f);
                }

                var image = SoftwareRenderer.Render(
                    instances, camera,
                    new RenderOptions { ShowSkeleton = true, ShowSockets = true }, cell, cell);

                for (int y = 0; y < cell; y++)
                    Array.Copy(image.Rgba, y * cell * 4, sheet, (y * columns * cell + i * cell) * 4, cell * 4);
            }

            Core.Textures.PngWriter.Write(
                target.Replace(".png", $"_{attachment.Socket}.png"), sheet, columns * cell, cell);
        }
    }

    private static int BoneNamed(PreviewModel model, string name)
    {
        for (int i = 0; i < model.Bones.Count; i++)
            if (string.Equals(model.Bones[i].Name, name, StringComparison.OrdinalIgnoreCase)) return i;
        return -1;
    }

    private static string Fmt(Vector3 v) => $"({v.X,7:0.#},{v.Y,7:0.#},{v.Z,7:0.#})";
}
