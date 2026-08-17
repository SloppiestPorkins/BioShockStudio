using System.Numerics;

namespace BioShockStudio.Core.Rendering;

/// <summary>
/// A ghost camera: a position and a heading, moved by keys and turned by the mouse.
/// </summary>
/// <remarks>
/// Kept in Core, and kept as an immutable record, so the navigation maths can be tested without a
/// window — which is the only way this project tests anything the window does.
/// </remarks>
public sealed record GhostCamera
{
    public Vector3 Position { get; init; }

    /// <summary>Heading about +Z, in radians.</summary>
    public float Yaw { get; init; }

    /// <summary>Elevation, in radians. Clamped short of straight up and straight down.</summary>
    public float Pitch { get; init; }

    /// <summary>Units per second while moving.</summary>
    public float Speed { get; init; } = 900f;

    public Vector3 Forward => PreviewCamera.Forward(Yaw, Pitch);

    /// <summary>
    /// The camera's right, which is the direction strafing uses.
    /// </summary>
    /// <remarks>
    /// <b>The studio basis is right-handed with +Y left</b> (see
    /// <c>ANIMATION_COORDINATE_SYSTEM.md</c>), so "right" is <c>forward × up</c> and not
    /// <c>up × forward</c>. Getting this backwards swaps A and D, which looks like a keybinding
    /// mistake rather than a basis one and is why it is written down here.
    /// </remarks>
    public Vector3 Right => Vector3.Normalize(Vector3.Cross(Forward, Vector3.UnitZ));

    /// <summary>Turns the camera. Pitch is clamped short of the poles so the up vector stays usable.</summary>
    public GhostCamera Look(float deltaYaw, float deltaPitch) => this with
    {
        Yaw = Yaw + deltaYaw,
        Pitch = Math.Clamp(Pitch + deltaPitch, -1.55f, 1.55f),
    };

    /// <summary>
    /// Moves the camera. <paramref name="forward"/>, <paramref name="right"/> and
    /// <paramref name="up"/> are each -1, 0 or 1.
    /// </summary>
    /// <remarks>
    /// Up is world up rather than the camera's own, which is what makes a free camera feel like a
    /// spectator rather than an aeroplane: looking down and pressing forward should move you along
    /// the floor and towards the floor, not roll the world.
    /// </remarks>
    public GhostCamera Move(float forward, float right, float up, float seconds, float speedScale = 1f)
    {
        var direction = Forward * forward + Right * right + Vector3.UnitZ * up;
        if (direction.LengthSquared() < 1e-9f) return this;

        return this with { Position = Position + Vector3.Normalize(direction) * (Speed * speedScale * seconds) };
    }

    /// <summary>The projection this camera implies, with planes suited to a level rather than a prop.</summary>
    public PreviewCamera ToPreviewCamera(float near = 4f, float far = 400_000f) =>
        PreviewCamera.LookFrom(Position, Yaw, Pitch, near, far);
}

/// <summary>One drawable thing in a level viewport: a model, where it sits, and how big it is.</summary>
public sealed record ViewportItem(PreviewModel Model, Matrix4x4 Transform, Vector3 Centre, float Radius)
{
    public int TriangleCount => Model.Indices.Count / 3;

    /// <summary>What kind of geometry this is — a mesh, a source brush, or the compiled world.</summary>
    public Level.LevelGeometryKind Kind { get; init; }

    /// <summary>The class of the actor that placed it, e.g. <c>StaticMeshActor</c> or <c>BlockingVolume</c>.</summary>
    public string ActorClass { get; init; } = "";

    /// <summary>
    /// Whether this is a volume rather than something the game draws.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>Decided by the actor's class, which is the game's own statement of what the thing is.</b>
    /// A blocking volume, a trigger, a zone or a water volume is a region the engine tests against;
    /// its brush is a box the size of a room and it is never rendered. Drawn anyway, they are the
    /// enormous grey slabs that swallow a level view.
    /// </para>
    /// <para>
    /// The suffix test is deliberate and covers the whole family — <c>BlockingVolume</c>,
    /// <c>ShockDamageVolume</c>, <c>TriggerVolume</c>, <c>FluidVolume</c> and the rest — because the
    /// game ships many and matching a fixed list would silently miss the ones nobody enumerated.
    /// <c>ZoneInfo</c> is named separately: it is a zone marker that does not end in "Volume".
    /// </para>
    /// </remarks>
    public bool IsVolume =>
        ActorClass.EndsWith("Volume", StringComparison.Ordinal)
        || ActorClass.EndsWith("Trigger", StringComparison.Ordinal)
        || ActorClass.EndsWith("ZoneInfo", StringComparison.Ordinal);
}

/// <summary>
/// Material classes known to carry <b>no base colour by design</b>, rather than by failure.
/// </summary>
/// <remarks>
/// <para>
/// Kept as documentation and for reporting, <b>not</b> as the filter's rule — the filter hides any
/// surface with no base colour, whatever the reason (see <c>LevelViewFilter.ShowUnpainted</c>).
/// This records <i>why</i> the largest groups have none, which is the part a future session would
/// otherwise have to re-derive.
/// </para>
/// <list type="bullet">
///   <item><description>
///     <c>LightBeamShader</c> — light shafts and glow cards. The engine blends them additively
///     through a falloff map; there is no base colour to report and the handoff already records
///     that "reporting one would be an invention". <b>19 instances, 1,338 triangles</b> on
///     <c>0-Lighthouse</c>: <c>Light_Beam_01</c>, <c>VolumeLight_Undewater</c>,
///     <c>MidTown_ShaderBeams</c>.
///   </description></item>
///   <item><description>
///     <c>FluidShader</c> / <c>FluidSurfaceShader</c> — water. <c>OilyOcean_Shader</c>,
///     <c>OceanUnderwater_Shader</c>, <c>RoundPuddleCalm</c>. The handoff records 83 of these, of
///     which 63 bind textures but none a <c>WaterDiffuseMap</c>. These are <i>real geometry</i>,
///     unlike a light shaft — the ocean surface genuinely exists — so hiding them is a rendering
///     decision, not a claim that they are not there.
///   </description></item>
/// </list>
/// <para>
/// <b>Classes, never names.</b> A material's class is the game's own statement of what it is;
/// <c>docs/HANDOFF.md</c> §4 records what a name allowlist cost the material reader once already.
/// </para>
/// </remarks>
public static class UnpaintedMaterials
{
    public static readonly IReadOnlySet<string> ByDesign = new HashSet<string>(StringComparer.Ordinal)
    {
        "LightBeamShader", "FluidShader", "FluidSurfaceShader",
    };

    public static bool HasNoBaseColourByDesign(string? className) =>
        className is not null && ByDesign.Contains(className);
}

/// <summary>What a level viewport should draw.</summary>
/// <remarks>
/// <para>
/// <b>Source brushes are off by default, and that is a consequence of decoding the compiled
/// world.</b> A brush is the <i>input</i> to CSG and the world is its <i>output</i>: the brush is
/// the solid block a designer drew, and the world is the room carved out of it. Drawing both puts
/// the uncarved blocks on top of the rooms — which is what a level view full of unexplained boxes
/// actually is. They remain available because they are the authored source and worth seeing.
/// </para>
/// <para>
/// <b>Volumes are off by default too.</b> A blocking volume or trigger is a region the engine tests
/// against, never draws, and its brush is the size of a room.
/// </para>
/// </remarks>
public sealed record LevelViewFilter
{
    public bool ShowWorld { get; init; } = true;
    public bool ShowMeshes { get; init; } = true;
    public bool ShowSourceBrushes { get; init; }
    public bool ShowVolumes { get; init; }

    /// <summary>
    /// Draw surfaces that resolve <b>no base colour</b>. <b>Off by default.</b>
    /// </summary>
    /// <remarks>
    /// <para>
    /// An unpainted surface draws as a flat pale sheet, and at the scale a level uses that is what
    /// swallows a view: light shafts, the ocean plane, glow cards, and the surfaces whose material
    /// simply did not resolve. <see cref="UnpaintedMaterials"/> records which of those have no base
    /// colour <i>by design</i>.
    /// </para>
    /// <para>
    /// <b>Hiding them costs almost no architecture, and that is measured rather than hoped.</b> On
    /// <c>0-Lighthouse</c> the compiled world has only <b>4</b> unpainted surfaces of 221 triangles;
    /// the rest are effects, water, and brushes that are already hidden. If that ever stops being
    /// true this filter would start punching holes in a level, so
    /// <c>UnpaintedSurfaceTests</c> pins the share.
    /// </para>
    /// <para>
    /// A <b>per-surface</b> filter, not a per-instance one: a mesh can be part painted and part not,
    /// and hiding the instance would take the painted half with it.
    /// </para>
    /// </remarks>
    public bool ShowUnpainted { get; init; }

    /// <summary>Everything, including the things the game never draws.</summary>
    public static readonly LevelViewFilter Everything =
        new() { ShowSourceBrushes = true, ShowVolumes = true, ShowUnpainted = true };

    public bool Accepts(ViewportItem item)
    {
        if (item.IsVolume) return ShowVolumes;

        return item.Kind switch
        {
            Level.LevelGeometryKind.BuiltWorld => ShowWorld,
            Level.LevelGeometryKind.Brush => ShowSourceBrushes,
            _ => ShowMeshes,
        };
    }
}

/// <summary>
/// Decides what a level viewport actually draws this frame.
/// </summary>
/// <remarks>
/// <para>
/// <b>Measured first, then designed.</b> Drawing all of <c>0-Lighthouse</c> takes about 1.6 seconds
/// a frame on the CPU rasteriser, and frustum culling alone only reaches 1.15 s — it keeps 399 of
/// 1,141 instances and 883,415 of 2,181,021 triangles, because Rapture's backdrop city is entirely
/// in view and is most of the map's geometry. The measurements are in
/// <c>LevelViewportPerformanceTests</c>.
/// </para>
/// <para>
/// <b>What actually bounds a frame here is pixels, not triangles.</b> 100,000 triangles cost 423 ms
/// at 960×600 and 147 ms at 480×300 — the same geometry, a third of the time. So the viewport
/// controls both: a triangle budget spends what geometry is worth drawing on the things that occupy
/// the most screen, and the caller scales resolution while the camera is moving.
/// </para>
/// <para>
/// <b>Culling is by whole instance.</b> The renderer projects and buckets every triangle it is given
/// before touching a pixel, so an off-screen triangle is not free and the rejection has to happen
/// above it.
/// </para>
/// </remarks>
public sealed class LevelViewport(IReadOnlyList<ViewportItem> items)
{
    public IReadOnlyList<ViewportItem> Items { get; } = items;

    public int TotalTriangles { get; } = items.Sum(i => i.TriangleCount);

    /// <summary>What one frame decided to draw, and what it left out.</summary>
    public sealed record Selection(
        IReadOnlyList<PreviewInstance> Instances, int Triangles, int Considered, int Dropped);

    /// <summary>
    /// Chooses what to draw from where the camera is.
    /// </summary>
    /// <param name="triangleBudget">
    /// The most geometry to draw. Exceeded only by a single instance that is on its own larger than
    /// the budget, because drawing nothing at all is worse than overrunning.
    /// </param>
    /// <remarks>
    /// Instances are ranked by <c>radius / distance</c> — roughly how much of the screen each can
    /// occupy — and taken until the budget is spent. That means the viewport degrades by dropping
    /// the least visible thing rather than by getting slower, and what it dropped is reported so the
    /// window can say so instead of quietly showing a partial level.
    /// </remarks>
    public Selection Select(
        GhostCamera camera, float aspect, int triangleBudget,
        LevelViewFilter? filter = null, float near = 4f, float far = 400_000f)
    {
        filter ??= new LevelViewFilter();

        var view = camera.ToPreviewCamera(near, far);
        var viewProjection =
            Matrix4x4.CreateLookAt(view.Eye, view.Target, Vector3.UnitZ)
            * Matrix4x4.CreatePerspectiveFieldOfView(
                view.FieldOfView, MathF.Max(aspect, 0.01f), near, MathF.Max(far, near * 2f));

        var planes = FrustumPlanes(viewProjection);

        var visible = new List<(ViewportItem Item, float Importance)>();
        foreach (var item in Items)
        {
            if (!filter.Accepts(item)) continue;
            if (!Inside(planes, item.Centre, item.Radius)) continue;
            float distance = MathF.Max(1f, Vector3.Distance(item.Centre, camera.Position));
            visible.Add((item, item.Radius / distance));
        }

        visible.Sort((a, b) => b.Importance.CompareTo(a.Importance));

        var chosen = new List<PreviewInstance>(visible.Count);
        int triangles = 0, dropped = 0;

        foreach (var (item, _) in visible)
        {
            int cost = item.TriangleCount;
            if (chosen.Count > 0 && triangles + cost > triangleBudget) { dropped++; continue; }
            chosen.Add(new PreviewInstance(item.Model, null, item.Transform));
            triangles += cost;
        }

        return new Selection(chosen, triangles, visible.Count, dropped);
    }

    /// <summary>The six frustum planes, from the rows of the view-projection matrix.</summary>
    private static Vector4[] FrustumPlanes(Matrix4x4 m) =>
    [
        new(m.M14 + m.M11, m.M24 + m.M21, m.M34 + m.M31, m.M44 + m.M41),
        new(m.M14 - m.M11, m.M24 - m.M21, m.M34 - m.M31, m.M44 - m.M41),
        new(m.M14 + m.M12, m.M24 + m.M22, m.M34 + m.M32, m.M44 + m.M42),
        new(m.M14 - m.M12, m.M24 - m.M22, m.M34 - m.M32, m.M44 - m.M42),
        new(m.M13, m.M23, m.M33, m.M43),
        new(m.M14 - m.M13, m.M24 - m.M23, m.M34 - m.M33, m.M44 - m.M43),
    ];

    private static bool Inside(Vector4[] planes, Vector3 centre, float radius)
    {
        foreach (var plane in planes)
        {
            var normal = new Vector3(plane.X, plane.Y, plane.Z);
            float length = normal.Length();
            if (length < 1e-9f) continue;
            if ((Vector3.Dot(normal, centre) + plane.W) / length < -radius) return false;
        }
        return true;
    }

    /// <summary>The bounding sphere of a transformed geometry, in world space.</summary>
    public static (Vector3 Centre, float Radius) BoundsOf(
        IReadOnlyList<Mesh.MeshVertex> vertices, Matrix4x4 transform)
    {
        if (vertices.Count == 0) return (Vector3.Zero, 0f);

        var min = new Vector3(float.MaxValue);
        var max = new Vector3(float.MinValue);
        foreach (var vertex in vertices)
        {
            var world = Vector3.Transform(vertex.Position, transform);
            min = Vector3.Min(min, world);
            max = Vector3.Max(max, world);
        }

        return ((min + max) * 0.5f, (max - min).Length() * 0.5f);
    }
}
