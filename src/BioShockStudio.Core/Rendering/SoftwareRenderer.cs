using System.Numerics;
using BioShockStudio.Core.Services;

namespace BioShockStudio.Core.Rendering;

/// <summary>An orbit camera: where it looks from, and at what.</summary>
public sealed record PreviewCamera
{
    /// <summary>Rotation about the model's up axis, in radians.</summary>
    public float Yaw { get; init; } = -0.9f;

    /// <summary>Elevation, in radians. Clamped short of the poles so the up vector stays usable.</summary>
    public float Pitch { get; init; } = 0.35f;

    public float Distance { get; init; } = 3f;
    public Vector3 Target { get; init; } = Vector3.Zero;
    public float FieldOfView { get; init; } = 45f * MathF.PI / 180f;

    /// <summary>
    /// Explicit near and far planes. Null lets the renderer derive them from the subject's size,
    /// which is right for a single asset and wrong for a level.
    /// </summary>
    /// <remarks>
    /// A level is hundreds of thousands of units across while the camera stands a few metres from a
    /// wall, so the derived planes put the near plane metres away — clipping the room the camera is
    /// standing in — and the far plane far enough to wreck depth precision. A walkable view has to
    /// state both.
    /// </remarks>
    public float? NearPlane { get; init; }
    public float? FarPlane { get; init; }

    /// <summary>
    /// A camera standing at a point and looking along a heading, rather than orbiting a subject.
    /// </summary>
    /// <remarks>
    /// <para>
    /// This is the whole of the "ghost camera": the renderer needs no free-camera mode, because an
    /// orbit camera whose target sits one step ahead of the eye <i>is</i> a free camera. The eye is
    /// derived as <c>Target + direction × Distance</c>, so a heading of <paramref name="yaw"/> /
    /// <paramref name="pitch"/> means the orbit direction is its opposite — hence the half turn and
    /// the negated pitch, which is the one place this is easy to get backwards.
    /// </para>
    /// <para>
    /// Keeping one camera type matters: the level viewport and the asset preview then go through
    /// exactly the same projection, so a level cannot be drawn with a subtly different view matrix
    /// from everything else in the application.
    /// </para>
    /// </remarks>
    public static PreviewCamera LookFrom(
        Vector3 position, float yaw, float pitch, float near, float far, float step = 100f)
    {
        var forward = Forward(yaw, pitch);
        return new PreviewCamera
        {
            Target = position + forward * step,
            Distance = step,
            Yaw = yaw + MathF.PI,
            Pitch = -pitch,
            NearPlane = near,
            FarPlane = far,
        };
    }

    /// <summary>The unit heading for a yaw and pitch, in the studio's +Z-up basis.</summary>
    public static Vector3 Forward(float yaw, float pitch)
    {
        float cos = MathF.Cos(pitch);
        return new Vector3(cos * MathF.Cos(yaw), cos * MathF.Sin(yaw), MathF.Sin(pitch));
    }

    public PreviewCamera Orbit(float deltaYaw, float deltaPitch) => this with
    {
        Yaw = Yaw + deltaYaw,
        Pitch = Math.Clamp(Pitch + deltaPitch, -1.5f, 1.5f),
    };

    public PreviewCamera Zoom(float factor) => this with { Distance = Math.Clamp(Distance * factor, 0.01f, 1e6f) };

    public Vector3 Eye
    {
        get
        {
            // The game is Z up, so elevation lifts Z and the orbit runs in the XY plane.
            float cos = MathF.Cos(Pitch);
            var direction = new Vector3(cos * MathF.Cos(Yaw), cos * MathF.Sin(Yaw), MathF.Sin(Pitch));
            return Target + direction * Distance;
        }
    }

    /// <summary>Frames a model so it fills a comfortable part of the view.</summary>
    public static PreviewCamera Frame(PreviewModel model) => Frame(model.Centre, model.Radius);

    public static PreviewCamera Frame(Vector3 centre, float radius) => new()
    {
        Target = centre,
        Distance = MathF.Max(radius, 0.001f) * 2.15f,
    };
}

/// <summary>One model placed in the view, optionally posed and optionally offset onto a socket.</summary>
public sealed record PreviewInstance(PreviewModel Model, Matrix4x4[]? Pose = null, Matrix4x4 Transform = default)
{
    public Matrix4x4 Transform { get; init; } = Transform == default ? Matrix4x4.Identity : Transform;
}

/// <summary>
/// A placed light, reduced to what a renderer needs.
/// </summary>
/// <remarks>
/// Deliberately not <c>LevelLight</c>: that record carries nullable fields, the source object and
/// the actor's class, because it reports what the <i>package</i> said. A renderer needs a position,
/// a colour and a reach, with the defaults already decided — and deciding them is the level layer's
/// job, not the rasteriser's.
/// </remarks>
public readonly record struct SceneLight(Vector3 Position, Vector3 Colour, float Radius, float Brightness);

/// <summary>What to draw.</summary>
public sealed record RenderOptions
{
    public bool Textured { get; init; } = true;

    /// <summary>
    /// Apply the material's normal and specular maps as well as its base colour.
    /// </summary>
    /// <remarks>
    /// The game ships all three and the mesh carries a per-vertex tangent basis, so the surface
    /// detail is real data rather than something this renderer invents. Turning it off shows the
    /// geometry alone, which is what you want when checking a skinning problem.
    /// </remarks>
    public bool Shaded { get; init; } = true;

    /// <summary>
    /// Honour the diffuse texture's alpha: cut out the holes, blend the translucent parts.
    /// </summary>
    /// <remarks>
    /// Turning it off draws every surface solid, which is the old behaviour and is occasionally
    /// what you want — a glass pane you cannot see is hard to tell from a glass pane that failed to
    /// load. A texture with no alpha takes the same path either way.
    /// </remarks>
    public bool Transparency { get; init; } = true;

    public bool Wireframe { get; init; }
    public bool ShowSkeleton { get; init; }
    public bool ShowSockets { get; init; }

    /// <summary>Highlighted bone, drawn in a different colour. -1 for none.</summary>
    public int SelectedBone { get; init; } = -1;

    /// <summary>
    /// Tint the triangles whose material did not resolve, so an untextured run is visibly a fault
    /// rather than a grey surface.
    /// </summary>
    /// <remarks>
    /// <para>
    /// This is the viewport half of the Problems panel. A run with no material draws in flat grey,
    /// and flat grey is also what a lot of BioShock legitimately looks like — bare concrete, painted
    /// metal, the inside of a crate. The two are indistinguishable by eye, which is exactly the
    /// class of fault this project keeps being caught by: <i>grey security cameras</i> were found by
    /// a user, not by the tool, and the tool had the evidence.
    /// </para>
    /// <para>
    /// Magenta is deliberate — it is the long-standing convention for a missing texture, and no
    /// shipped BioShock surface is that colour, so the overlay can never be mistaken for art.
    /// </para>
    /// </remarks>
    public bool HighlightUnresolvedSurfaces { get; init; }

    /// <summary>
    /// Point lights to shade with, in the studio's basis. Empty means the fixed studio lighting.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>This is not the game's lighting model and does not claim to be.</b> BioShock bakes its
    /// static lighting into lightmap atlases (<c>docs/research/bsp.md</c> §5.5), which this project
    /// reads no part of; what a light actor carries is a colour, a brightness and a radius, and this
    /// applies them as simple point lights with inverse-square-ish falloff. The result is
    /// <i>plausible</i>, not authentic — a level lit this way looks like the level rather than like
    /// the game.
    /// </para>
    /// <para>
    /// It is worth doing anyway because the alternative is two fixed directions, under which every
    /// room is lit identically and the level's own character is invisible. It is opt-in for exactly
    /// that reason: a viewer should be able to see the geometry without a lighting model on top.
    /// </para>
    /// </remarks>
    public IReadOnlyList<SceneLight> Lights { get; init; } = [];

    /// <summary>How strongly <see cref="Lights"/> contribute, against the fixed studio lighting.</summary>
    public float LightIntensity { get; init; } = 1f;

    /// <summary>
    /// Draw surfaces that resolve no base colour. <b>Off by default</b> in a level view.
    /// </summary>
    /// <remarks>
    /// An unpainted surface draws as a flat pale sheet — a light shaft, the ocean plane, a glow
    /// card, or a material that did not resolve. See <c>LevelViewFilter.ShowUnpainted</c>, which
    /// records how little architecture hiding them actually costs.
    /// </remarks>
    public bool ShowUnpainted { get; init; } = true;

    /// <summary>Draw deliberately unpainted effect materials such as godrays and water.</summary>
    public bool ShowEffects { get; init; } = true;

    /// <summary>
    /// Modulate a surface by its baked lightmap atlas, sampled <b>per pixel</b>.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>Per pixel is the whole point of a lightmap, and this renderer had none at all.</b> Baked
    /// light reached only the GPU viewport, and there only per <i>vertex</i> — sampled into
    /// <c>MeshVertex.BakedLight</c> by <c>LevelViewportService</c> and interpolated across the
    /// triangle. BSP surfaces are large flat polygons, so a per-vertex sample of a lightmap throws
    /// away almost everything the lightmap contains: a wall lit by a lamp in its middle has four
    /// corner samples and reconstructs a flat gradient.
    /// </para>
    /// <para>
    /// It also meant the lightmap work could not be <i>looked at</i> in a test — the software
    /// renderer is the path this project renders and checks, and it drew every level unlit. That is
    /// why <c>docs/ROADMAP.md</c> Gate 0 item 3 asks for a lit/unlit comparison render before this
    /// becomes a default.
    /// </para>
    /// <para>
    /// The shipped <c>LayerLighting.hlsl</c> settles the combination: sample every layer, unswizzle
    /// <c>.yzx</c> into three scalar luminances, multiply each by the matching light actor's colour
    /// and diffuse-facing term, then add the results. The per-triangle metadata preserves that
    /// actor/atlas pairing while this path samples it per fragment.
    /// </para>
    /// <para>
    /// Kept, off, because it is the plumbing the real implementation needs and because it is the
    /// only path that can show the fault at all — the per-vertex GPU path has the same defect and
    /// blurs it into a dull tint.
    /// </para>
    /// </remarks>
    public bool BakedLightmaps { get; init; }

    public byte BackgroundGrey { get; init; } = 32;
}

/// <summary>
/// A CPU triangle rasteriser for the asset preview.
/// </summary>
/// <remarks>
/// <para>
/// Software rather than GPU deliberately. Avalonia has no built-in 3D, and the alternatives — an
/// OpenGL control or a new rendering dependency — cannot be rendered in a headless test. This can,
/// so the preview is verified the same way everything else in this project is: by rendering it and
/// checking the result, rather than by trusting that it looks right on someone's screen.
/// </para>
/// <para>
/// It is not fast in absolute terms and does not need to be. The largest asset here is ~9,000
/// triangles, which is a few milliseconds at preview resolution.
/// </para>
/// </remarks>
public static class SoftwareRenderer
{
    public static PreviewImage Render(
        PreviewModel model,
        PreviewCamera camera,
        RenderOptions options,
        int width,
        int height,
        Matrix4x4[]? pose = null) =>
        Render([new PreviewInstance(model, pose)], camera, options, width, height);

    /// <summary>
    /// Draws several models in one view.
    /// </summary>
    /// <remarks>
    /// This is what a first-person set needs. The hands and the weapon are two rigs with their own
    /// skeletons and their own animations, played together at a socket — merging them into one
    /// skeleton would destroy that structure, so they are drawn as separate instances and the
    /// weapon carries the host's socket-bone transform.
    /// </remarks>
    public static PreviewImage Render(
        IReadOnlyList<PreviewInstance> instances,
        PreviewCamera camera,
        RenderOptions options,
        int width,
        int height)
    {
        width = Math.Max(1, width);
        height = Math.Max(1, height);

        var target = new RenderTarget(width, height, options.BackgroundGrey);
        if (instances.Count == 0) return new PreviewImage(width, height, target.Colour);

        float radius = 0f;
        foreach (var instance in instances) radius = MathF.Max(radius, instance.Model.Radius);

        var view = LookAt(camera.Eye, camera.Target);

        // The derived planes size themselves to the subject, which is right for one asset and wrong
        // for a level: standing a few metres from a wall inside a 300,000-unit map, the derived near
        // plane would clip the room the camera is in. A camera that states its planes keeps them.
        var projection = Perspective(
            camera.FieldOfView, (float)width / height,
            camera.NearPlane ?? MathF.Max(0.0005f, MathF.Min(camera.Distance, radius) * 0.01f),
            camera.FarPlane ?? (camera.Distance + radius) * 4f);
        var viewProjection = view * projection;

        foreach (var instance in instances)
        {
            var model = instance.Model;
            var skinning = instance.Pose is null ? null : model.SkinningMatrices(instance.Pose);

            var positions = model.SkinPositions(skinning);
            var normals = model.SkinNormals(skinning);

            bool wantsBasis = options.Shaded && options.Textured && model.NormalMap is not null;
            var tangents = wantsBasis ? model.SkinTangents(skinning) : null;
            var binormals = wantsBasis ? model.SkinBinormals(skinning) : null;

            if (!instance.Transform.IsIdentity)
            {
                for (int i = 0; i < positions.Length; i++)
                {
                    positions[i] = Vector3.Transform(positions[i], instance.Transform);
                    normals[i] = Vector3.Normalize(Vector3.TransformNormal(normals[i], instance.Transform));
                    if (tangents is not null) tangents[i] = Vector3.TransformNormal(tangents[i], instance.Transform);
                    if (binormals is not null) binormals[i] = Vector3.TransformNormal(binormals[i], instance.Transform);
                }
            }

            if (model.HasGeometry && !options.Wireframe)
                DrawSolid(target, model, positions, normals, tangents, binormals, viewProjection, camera, options);
            else if (model.HasGeometry)
                DrawWireframe(target, model, positions, viewProjection);

            if (options.ShowSkeleton || !model.HasGeometry)
                DrawSkeleton(target, model, instance.Pose, instance.Transform, viewProjection, options);

            if (options.ShowSockets) DrawSockets(target, model, instance.Pose, instance.Transform, viewProjection);
        }

        return new PreviewImage(width, height, target.Colour);
    }

    // ------------------------------------------------------------------ drawing

    private static void DrawSolid(
        RenderTarget target,
        PreviewModel model,
        Vector3[] positions,
        Vector3[] normals,
        Vector3[]? tangents,
        Vector3[]? binormals,
        Matrix4x4 viewProjection,
        PreviewCamera camera,
        RenderOptions options)
    {
        var eye = camera.Eye;

        // Hoisted to an array: the shading lambda runs per pixel, and enumerating an interface
        // there costs more than the lighting arithmetic it is fetching.
        var lights = options.Lights as SceneLight[] ?? [.. options.Lights];

        // A mesh draws one run per material, so the maps are picked per triangle rather than once.
        // Resolved into arrays here so the inner loop indexes rather than walking the surface list.
        int surfaceCount = model.Surfaces.Count;
        var textures = new PreviewImage?[surfaceCount];
        var normalMaps = new PreviewImage?[surfaceCount];
        var specularMaps = new PreviewImage?[surfaceCount];
        var lightMaps = new PreviewImage?[surfaceCount];

        for (int s = 0; s < surfaceCount; s++)
        {
            var surface = model.Surfaces[s];
            textures[s] = options.Textured ? surface.Texture : null;
            normalMaps[s] = options.Shaded && options.Textured ? surface.NormalMap : null;
            specularMaps[s] = options.Shaded && options.Textured ? surface.SpecularMap : null;
            lightMaps[s] = options.BakedLightmaps ? surface.LightMapTexture : null;
        }

        // Alpha is taken from the diffuse texture rather than from the material's blend mode, whose
        // values are still UNKNOWN — see docs/research/materials.md. A texture whose alpha is 255
        // everywhere takes exactly the path it always did, so nothing opaque can change.
        //
        // One surface carrying alpha puts the whole mesh through the sorted two-pass path: a window
        // in a hull has to be drawn after what is behind it, and which run it belongs to does not
        // change that. Fragments of an opaque run report alpha 255 and so all land in the first pass,
        // exactly as before.
        bool hasAlpha = options.Transparency
                        && textures.Any(t => t is not null && t.HasTransparency);

        // Opaque first, then the translucent surfaces back to front over the top. Without the sort a
        // window drawn before what is behind it hides it.
        var order = hasAlpha
            ? SortedTriangles(model, positions, camera.Eye)
            : null;

        // Project once rather than once per band.
        int triangleCount = model.Indices.Count / 3;
        var projected = new (Projected A, Projected B, Projected C, int IA, int IB, int IC, bool Ok)[triangleCount];

        for (int t = 0; t < triangleCount; t++)
        {
            int i = t * 3;
            int ia = model.Indices[i], ib = model.Indices[i + 1], ic = model.Indices[i + 2];
            if (ia >= positions.Length || ib >= positions.Length || ic >= positions.Length) continue;

            if (Project(positions[ia], viewProjection, target, out var pa)
                && Project(positions[ib], viewProjection, target, out var pb)
                && Project(positions[ic], viewProjection, target, out var pc))
            {
                projected[t] = (pa, pb, pc, ia, ib, ic, true);
            }
        }

        // Drawing is split into horizontal bands, one per worker. A band owns its rows outright, so
        // its depth writes cannot race another's — which is why the split is by scanline and not by
        // triangle. The whole model is walked per band, but the bounding-box reject is a handful of
        // comparisons and the per-pixel work is what actually costs.
        int bands = Math.Clamp(Environment.ProcessorCount, 1, 16);
        int rowsPerBand = Math.Max(1, (target.Height + bands - 1) / bands);

        // Each band gets only the triangles that reach it. Walking the whole model per band costs
        // more in bounding-box setup than the parallelism buys back — on the hands that is 8,726
        // triangles times sixteen bands for the sake of the few hundred each band actually draws.
        var buckets = new List<int>[bands];
        for (int i = 0; i < bands; i++) buckets[i] = [];

        for (int t = 0; t < triangleCount; t++)
        {
            int index = order is null ? t : order[t];
            var (pa, pb, pc, _, _, _, ok) = projected[index];
            if (!ok) continue;

            int top = (int)MathF.Floor(Math.Min(pa.Y, Math.Min(pb.Y, pc.Y)));
            int bottom = (int)MathF.Ceiling(Math.Max(pa.Y, Math.Max(pb.Y, pc.Y)));
            if (bottom < 0 || top > target.Height - 1) continue;

            int firstBand = Math.Clamp(top / rowsPerBand, 0, bands - 1);
            int lastBand = Math.Clamp(bottom / rowsPerBand, 0, bands - 1);

            // Order matters in the blended pass, and appending in sorted order preserves it.
            for (int band = firstBand; band <= lastBand; band++) buckets[band].Add(index);
        }

        for (int pass = 0; pass < (hasAlpha ? 2 : 1); pass++)
        {
            bool blendPass = pass == 1;

            Parallel.For(0, bands, band =>
            {
            int firstRow = band * rowsPerBand;
            int lastRow = Math.Min(target.Height - 1, firstRow + rowsPerBand - 1);
            if (firstRow > lastRow) return;

            foreach (int index in buckets[band])
            {
                var (pa, pb, pc, a, b, c, ok) = projected[index];
                if (!ok) continue;

                int surface = index < model.TriangleSurface.Count ? model.TriangleSurface[index] : -1;

                var texture = surface >= 0 ? textures[surface] : null;

                // A surface with no base colour draws as a flat pale sheet — a light shaft, the
                // ocean plane, or a material that did not resolve. At a level's scale those are what
                // swallow a view.
                bool effect = surface >= 0 && model.Surfaces[surface].NoBaseColourByDesign;
                if (texture is null && !(effect ? options.ShowEffects : options.ShowUnpainted)) continue;

                var normalMap = surface >= 0 ? normalMaps[surface] : null;
                var specularMap = surface >= 0 ? specularMaps[surface] : null;
                var lightMap = surface >= 0 ? lightMaps[surface] : null;
                var bakedLighting = options.BakedLightmaps && index < model.TriangleBakedLighting.Count
                    ? model.TriangleBakedLighting[index]
                    : null;

                // A run whose slot named nothing, or that no section covers at all. Both draw grey
                // and neither is distinguishable from grey paint without saying so.
                bool unresolved = options.HighlightUnresolvedSurfaces
                                  && (surface < 0 || model.Surfaces[surface].MaterialName is null);

                RasteriseTriangle(target, pa, pb, pc, (bary, depth, x, y) =>
                {
                    var uv = model.Vertices[a].Uv * bary.X
                             + model.Vertices[b].Uv * bary.Y
                             + model.Vertices[c].Uv * bary.Z;

                    byte r, g, bl, alpha;
                    if (texture is not null) (r, g, bl, alpha) = SampleRgba(texture, uv);
                    else { r = g = bl = 190; alpha = 255; }

                    // Tinted rather than replaced, so the shading still reads and the shape of the
                    // affected run stays legible — a flat magenta silhouette hides which part of the
                    // mesh is at fault, which is the only thing the overlay is for.
                    if (unresolved)
                    {
                        r = (byte)((r + 255 * 2) / 3);
                        g /= 3;
                        bl = (byte)((bl + 255 * 2) / 3);
                    }

                    if (hasAlpha)
                    {
                        // Fully transparent texels are holes, not faint surfaces: a grating, a
                        // chain-link fence, a hair card. Drawing them at all fills the gaps in.
                        if (alpha < CutoutThreshold) return;

                        // Each fragment goes in exactly one pass, so nothing is drawn twice.
                        bool solid = alpha >= OpaqueThreshold;
                        if (solid == blendPass) return;
                    }

                    var normal = Vector3.Normalize(
                        normals[a] * bary.X + normals[b] * bary.Y + normals[c] * bary.Z);
                    var point = positions[a] * bary.X + positions[b] * bary.Y + positions[c] * bary.Z;

                    // The shipped tangent basis, interpolated, so the normal map is applied in the
                    // space it was authored in rather than one derived here.
                    if (normalMap is not null && tangents is not null && binormals is not null)
                    {
                        var tangent = tangents[a] * bary.X + tangents[b] * bary.Y + tangents[c] * bary.Z;
                        var binormal = binormals[a] * bary.X + binormals[b] * bary.Y + binormals[c] * bary.Z;
                        normal = ApplyNormalMap(normalMap, uv, normal, tangent, binormal);
                    }

                    // A headlamp: the light sits at the camera, so nothing is ever unlit and the
                    // shape reads from any angle without a lighting rig to set up.
                    var toEye = Vector3.Normalize(eye - point);
                    float lambert = MathF.Abs(Vector3.Dot(normal, toEye));
                    float shade = 0.18f + 0.82f * lambert;

                    float red = r * shade;
                    float green = g * shade;
                    float blue = bl * shade;

                    // The baked lightmap, sampled per pixel at this fragment's own atlas coordinate
                    // rather than interpolated from three corner samples. It REPLACES the headlamp
                    // for this surface: the headlamp exists so unlit geometry stays inspectable, and
                    // a surface that carries the game's own baked light does not need it — keeping
                    // both washes the bake out to the point where lit and unlit look alike, which
                    // would defeat the comparison this exists to make possible.
                    if (bakedLighting is { Layers.Count: > 0 })
                    {
                        var primaryUv = model.Vertices[a].LightMapUv * bary.X
                                        + model.Vertices[b].LightMapUv * bary.Y
                                        + model.Vertices[c].LightMapUv * bary.Z;
                        var total = Vector3.Zero;

                        foreach (var layer in bakedLighting.Layers)
                        {
                            var (rawR, rawG, rawB, _) = SampleRgba(layer.Texture, primaryUv + layer.UvOffset);
                            float[] luminance = [rawG / 255f, rawB / 255f, rawR / 255f];
                            for (int slot = 0; slot < Math.Min(3, layer.Lights.Count); slot++)
                            {
                                if (layer.Lights[slot] is not { } light) continue;
                                var toLight = light.Position - point;
                                float distance = toLight.Length();
                                if (distance < 1e-3f) continue;
                                float facing = MathF.Max(0f, Vector3.Dot(normal, toLight / distance));
                                total += light.Colour * (luminance[slot] * facing);
                            }
                        }

                        red = r * total.X;
                        green = g * total.Y;
                        blue = bl * total.Z;
                    }
                    else if (lightMap is not null)
                    {
                        var lightUv = model.Vertices[a].LightMapUv * bary.X
                                      + model.Vertices[b].LightMapUv * bary.Y
                                      + model.Vertices[c].LightMapUv * bary.Z;

                        var (lr8, lg8, lb8, _) = SampleRgba(lightMap, lightUv);
                        red = r * (lr8 / 255f);
                        green = g * (lg8 / 255f);
                        blue = bl * (lb8 / 255f);
                    }

                    // The level's own lights, when a caller supplied them. They ADD to the headlamp
                    // rather than replacing it, so a corner no light reaches is dim rather than
                    // black — this is a viewer, and geometry nobody lit still has to be inspectable.
                    if (lights.Length > 0)
                    {
                        float lr = 0f, lg = 0f, lb = 0f;

                        foreach (var light in lights)
                        {
                            var toLight = light.Position - point;
                            float distanceSquared = toLight.LengthSquared();
                            if (distanceSquared > light.Radius * light.Radius) continue;

                            float distance = MathF.Sqrt(distanceSquared);
                            if (distance < 1e-3f) continue;

                            // Linear falloff to the light's stated radius. Unreal's own attenuation
                            // is not documented here and inverse-square alone leaves a level almost
                            // black at these scales, where a radius is measured in thousands of
                            // centimetres — so this is a readable approximation and is labelled one.
                            float attenuation = 1f - distance / light.Radius;
                            float facing = MathF.Max(0f, Vector3.Dot(normal, toLight / distance));
                            float contribution = attenuation * attenuation * facing * light.Brightness;

                            lr += light.Colour.X * contribution;
                            lg += light.Colour.Y * contribution;
                            lb += light.Colour.Z * contribution;
                        }

                        float strength = options.LightIntensity;
                        red += r * lr * strength;
                        green += g * lg * strength;
                        blue += bl * lb * strength;
                    }

                    if (specularMap is not null)
                    {
                        // Blinn-Phong against the headlamp, so the light and the eye coincide and
                        // the half vector is the view direction.
                        float highlight = MathF.Pow(MathF.Max(0f, Vector3.Dot(normal, toEye)), 24f);
                        var (sr, sg, sb) = Sample(specularMap, uv);
                        red += sr * highlight;
                        green += sg * highlight;
                        blue += sb * highlight;
                    }

                    if (blendPass)
                        target.Blend(x, y, Clamp(red), Clamp(green), Clamp(blue), alpha / 255f);
                    else
                        target.Plot(x, y, depth, Clamp(red), Clamp(green), Clamp(blue));
                }, firstRow, lastRow);
            }
            });
        }
    }

    /// <summary>Below this, a texel is a hole rather than a faint surface.</summary>
    private const byte CutoutThreshold = 8;

    /// <summary>At or above this, a texel is treated as solid and written with depth.</summary>
    private const byte OpaqueThreshold = 250;

    /// <summary>
    /// Triangle indices ordered back to front from the eye, by centroid distance.
    /// </summary>
    /// <remarks>
    /// Per triangle rather than per pixel, so two translucent surfaces that intersect will still
    /// resolve wrongly along the intersection. That is the standard limitation of sorted blending
    /// and it is not worth an order-independent scheme for a preview.
    /// </remarks>
    private static int[] SortedTriangles(PreviewModel model, Vector3[] positions, Vector3 eye)
    {
        int count = model.Indices.Count / 3;
        var order = new int[count];
        var distance = new float[count];

        for (int t = 0; t < count; t++)
        {
            order[t] = t;
            int a = model.Indices[t * 3], b = model.Indices[t * 3 + 1], c = model.Indices[t * 3 + 2];
            if (a >= positions.Length || b >= positions.Length || c >= positions.Length) continue;

            var centroid = (positions[a] + positions[b] + positions[c]) / 3f;
            distance[t] = -(centroid - eye).LengthSquared();
        }

        Array.Sort(distance, order);
        return order;
    }

    private static void DrawWireframe(
        RenderTarget target, PreviewModel model, Vector3[] positions, Matrix4x4 viewProjection)
    {
        for (int i = 0; i + 2 < model.Indices.Count; i += 3)
        {
            int a = model.Indices[i], b = model.Indices[i + 1], c = model.Indices[i + 2];
            if (a >= positions.Length || b >= positions.Length || c >= positions.Length) continue;

            DrawLine(target, positions[a], positions[b], viewProjection, 150, 190, 210);
            DrawLine(target, positions[b], positions[c], viewProjection, 150, 190, 210);
            DrawLine(target, positions[c], positions[a], viewProjection, 150, 190, 210);
        }
    }

    private static void DrawSkeleton(
        RenderTarget target,
        PreviewModel model,
        Matrix4x4[]? pose,
        Matrix4x4 transform,
        Matrix4x4 viewProjection,
        RenderOptions options)
    {
        for (int i = 0; i < model.Bones.Count; i++)
        {
            var bone = model.Bones[i];
            if (bone.Parent < 0) continue;

            var from = Vector3.Transform(
                (pose is null ? model.Bones[bone.Parent].RestGlobal : pose[bone.Parent]).Translation, transform);
            var to = Vector3.Transform((pose is null ? bone.RestGlobal : pose[i]).Translation, transform);

            bool selected = i == options.SelectedBone || bone.Parent == options.SelectedBone;
            if (selected) DrawLine(target, from, to, viewProjection, 255, 210, 90, ignoreDepth: true);
            else DrawLine(target, from, to, viewProjection, 120, 200, 255, ignoreDepth: true);
        }
    }

    private static void DrawSockets(
        RenderTarget target, PreviewModel model, Matrix4x4[]? pose, Matrix4x4 transform, Matrix4x4 viewProjection)
    {
        // A socket is a point, so it is drawn as a small axis cross scaled to the model.
        float size = model.Radius * 0.05f;

        foreach (var socket in model.Sockets)
        {
            if (socket.Bone < 0 || socket.Bone >= model.Bones.Count) continue;
            // The socket's own offset from its bone, not just the bone: most are identity, but
            // FireballSocket sits 65.8 cm out and drawing the marker on the bone hides that.
            var bone = pose is null ? model.Bones[socket.Bone].RestGlobal : pose[socket.Bone];
            var matrix = socket.On(bone);
            var origin = Vector3.Transform(matrix.Translation, transform);

            DrawLine(target, origin - Vector3.UnitX * size, origin + Vector3.UnitX * size, viewProjection, 255, 120, 120, true);
            DrawLine(target, origin - Vector3.UnitY * size, origin + Vector3.UnitY * size, viewProjection, 120, 255, 120, true);
            DrawLine(target, origin - Vector3.UnitZ * size, origin + Vector3.UnitZ * size, viewProjection, 120, 160, 255, true);
        }
    }

    // ------------------------------------------------------------------ primitives

    private readonly record struct Projected(float X, float Y, float Depth);

    private static bool Project(Vector3 point, Matrix4x4 viewProjection, RenderTarget target, out Projected result)
    {
        var clip = Vector4.Transform(new Vector4(point, 1f), viewProjection);
        result = default;

        // Anything at or behind the eye cannot be projected; the triangle is dropped rather than
        // clipped, which is acceptable for a preview and never draws something wrong.
        if (clip.W <= 1e-4f) return false;

        float x = clip.X / clip.W;
        float y = clip.Y / clip.W;
        float z = clip.Z / clip.W;

        result = new Projected(
            (x * 0.5f + 0.5f) * target.Width,
            (1f - (y * 0.5f + 0.5f)) * target.Height,
            z);
        return true;
    }

    private static void RasteriseTriangle(
        RenderTarget target, Projected a, Projected b, Projected c, Action<Vector3, float, int, int> shade) =>
        RasteriseTriangle(target, a, b, c, shade, 0, target.Height - 1);

    /// <summary>
    /// Rasterises a triangle, clipped to a band of scanlines.
    /// </summary>
    /// <remarks>
    /// The band is what makes drawing parallel safe. A thread that owns rows <c>[firstRow, lastRow]</c>
    /// is the only writer of those pixels and of their depth, so no triangle can race another —
    /// splitting by triangle instead would have two threads fighting over the same depth value.
    /// </remarks>
    private static void RasteriseTriangle(
        RenderTarget target, Projected a, Projected b, Projected c, Action<Vector3, float, int, int> shade,
        int firstRow, int lastRow)
    {
        float area = (b.X - a.X) * (c.Y - a.Y) - (b.Y - a.Y) * (c.X - a.X);
        if (MathF.Abs(area) < 1e-6f) return;

        int minX = Math.Max(0, (int)MathF.Floor(Math.Min(a.X, Math.Min(b.X, c.X))));
        int maxX = Math.Min(target.Width - 1, (int)MathF.Ceiling(Math.Max(a.X, Math.Max(b.X, c.X))));
        int minY = Math.Max(firstRow, (int)MathF.Floor(Math.Min(a.Y, Math.Min(b.Y, c.Y))));
        int maxY = Math.Min(lastRow, (int)MathF.Ceiling(Math.Max(a.Y, Math.Max(b.Y, c.Y))));

        for (int y = minY; y <= maxY; y++)
        {
            for (int x = minX; x <= maxX; x++)
            {
                float px = x + 0.5f;
                float py = y + 0.5f;

                float w0 = ((b.X - a.X) * (py - a.Y) - (b.Y - a.Y) * (px - a.X)) / area;
                float w1 = ((c.X - b.X) * (py - b.Y) - (c.Y - b.Y) * (px - b.X)) / area;
                float w2 = ((a.X - c.X) * (py - c.Y) - (a.Y - c.Y) * (px - c.X)) / area;

                // Sign-agnostic so that back faces still draw: BioShock's meshes include
                // single-sided sheets that would otherwise vanish from one side.
                if (w0 < 0f || w1 < 0f || w2 < 0f)
                {
                    if (w0 > 0f || w1 > 0f || w2 > 0f) continue;
                }

                var bary = new Vector3(w1, w2, w0);
                float depth = a.Depth * bary.X + b.Depth * bary.Y + c.Depth * bary.Z;
                if (!target.DepthTest(x, y, depth)) continue;

                shade(bary, depth, x, y);
            }
        }
    }

    private static void DrawLine(
        RenderTarget target, Vector3 from, Vector3 to, Matrix4x4 viewProjection,
        byte r, byte g, byte b, bool ignoreDepth = false)
    {
        if (!Project(from, viewProjection, target, out var a) || !Project(to, viewProjection, target, out var c)) return;

        int steps = (int)MathF.Max(MathF.Abs(c.X - a.X), MathF.Abs(c.Y - a.Y));
        steps = Math.Clamp(steps, 1, 4096);

        for (int i = 0; i <= steps; i++)
        {
            float t = (float)i / steps;
            int x = (int)MathF.Round(a.X + (c.X - a.X) * t);
            int y = (int)MathF.Round(a.Y + (c.Y - a.Y) * t);
            float depth = a.Depth + (c.Depth - a.Depth) * t;

            // Overlays are drawn slightly in front so a skeleton inside a mesh stays visible.
            if (ignoreDepth) target.PlotOver(x, y, r, g, b);
            else if (target.DepthTest(x, y, depth)) target.Plot(x, y, depth, r, g, b);
        }
    }

    private static byte Clamp(float value) => (byte)Math.Clamp(value, 0f, 255f);

    /// <summary>
    /// Perturbs a surface normal by a tangent-space normal map.
    /// </summary>
    /// <remarks>
    /// The map stores a direction as a colour, so each channel is expanded from 0..1 back to -1..1.
    /// A degenerate tangent basis — some vertices have one — falls back to the interpolated normal
    /// rather than producing a NaN that would leave a black hole in the surface.
    /// </remarks>
    private static Vector3 ApplyNormalMap(
        PreviewImage map, Vector2 uv, Vector3 normal, Vector3 tangent, Vector3 binormal)
    {
        if (tangent.LengthSquared() < 1e-8f || binormal.LengthSquared() < 1e-8f) return normal;

        var (r, g, b) = Sample(map, uv);
        var sampled = new Vector3(r / 127.5f - 1f, g / 127.5f - 1f, b / 127.5f - 1f);
        if (sampled.LengthSquared() < 1e-6f) return normal;

        var perturbed = Vector3.Normalize(tangent) * sampled.X
                        + Vector3.Normalize(binormal) * sampled.Y
                        + normal * sampled.Z;

        return perturbed.LengthSquared() > 1e-8f ? Vector3.Normalize(perturbed) : normal;
    }

    private static (byte R, byte G, byte B) Sample(PreviewImage texture, Vector2 uv)
    {
        var (r, g, b, _) = SampleRgba(texture, uv);
        return (r, g, b);
    }

    /// <summary>
    /// Bilinear texture sample, wrapping at the edges. The game's V runs top-down, the same flip the
    /// exporters apply.
    /// </summary>
    /// <remarks>
    /// Nearest-neighbour was what made every surface look blocky up close, whatever the mesh was
    /// doing — the tell was texels visible as squares on a model only a few hundred triangles big.
    /// Four taps per pixel is a real cost in a software rasteriser and it is the single largest
    /// difference to how the preview reads.
    /// </remarks>
    private static (byte R, byte G, byte B, byte A) SampleRgba(PreviewImage texture, Vector2 uv)
    {
        int w = texture.Width, h = texture.Height;
        if (w <= 0 || h <= 0) return (190, 190, 190, 255);

        // Half-texel offset so a sample at the centre of a texel returns it exactly.
        float fx = Wrap(uv.X) * w - 0.5f;
        float fy = Wrap(uv.Y) * h - 0.5f;

        int x0 = (int)MathF.Floor(fx), y0 = (int)MathF.Floor(fy);
        float tx = fx - x0, ty = fy - y0;

        int x1 = Mod(x0 + 1, w), y1 = Mod(y0 + 1, h);
        x0 = Mod(x0, w);
        y0 = Mod(y0, h);

        var (r00, g00, b00, a00) = Texel(texture, x0, y0);
        var (r10, g10, b10, a10) = Texel(texture, x1, y0);
        var (r01, g01, b01, a01) = Texel(texture, x0, y1);
        var (r11, g11, b11, a11) = Texel(texture, x1, y1);

        return (
            Mix(r00, r10, r01, r11), Mix(g00, g10, g01, g11),
            Mix(b00, b10, b01, b11), Mix(a00, a10, a01, a11));

        byte Mix(byte v00, byte v10, byte v01, byte v11)
        {
            float top = v00 + (v10 - v00) * tx;
            float bottom = v01 + (v11 - v01) * tx;
            return (byte)Math.Clamp(top + (bottom - top) * ty, 0f, 255f);
        }

        static int Mod(int value, int size)
        {
            int result = value % size;
            return result < 0 ? result + size : result;
        }

        static float Wrap(float value)
        {
            value -= MathF.Floor(value);
            return value < 0f ? value + 1f : value;
        }
    }

    private static (byte R, byte G, byte B, byte A) Texel(PreviewImage texture, int x, int y)
    {
        int offset = (y * texture.Width + x) * 4;
        if (offset < 0 || offset + 3 >= texture.Rgba.Length) return (190, 190, 190, 255);
        return (texture.Rgba[offset], texture.Rgba[offset + 1], texture.Rgba[offset + 2], texture.Rgba[offset + 3]);
    }

    // ------------------------------------------------------------------ matrices

    private static float NearPlane(PreviewCamera camera, PreviewModel model) =>
        MathF.Max(0.0005f, MathF.Min(camera.Distance, model.Radius) * 0.01f);

    private static float FarPlane(PreviewCamera camera, PreviewModel model) =>
        (camera.Distance + model.Radius) * 4f;

    private static Matrix4x4 LookAt(Vector3 eye, Vector3 target)
    {
        var up = Vector3.UnitZ;
        var forward = target - eye;
        if (forward.LengthSquared() < 1e-8f) forward = -Vector3.UnitX;

        // Looking straight down the up axis leaves the basis undefined; nudging avoids a NaN frame.
        if (MathF.Abs(Vector3.Dot(Vector3.Normalize(forward), up)) > 0.9999f) up = Vector3.UnitY;

        return Matrix4x4.CreateLookAt(eye, target, up);
    }

    private static Matrix4x4 Perspective(float fieldOfView, float aspect, float near, float far) =>
        Matrix4x4.CreatePerspectiveFieldOfView(fieldOfView, MathF.Max(aspect, 0.01f), near, MathF.Max(far, near * 2f));

    // ------------------------------------------------------------------ target

    private sealed class RenderTarget
    {
        public int Width { get; }
        public int Height { get; }
        public byte[] Colour { get; }

        private readonly float[] _depth;

        public RenderTarget(int width, int height, byte background)
        {
            Width = width;
            Height = height;
            Colour = new byte[width * height * 4];
            _depth = new float[width * height];

            for (int i = 0; i < _depth.Length; i++)
            {
                _depth[i] = float.MaxValue;
                Colour[i * 4] = background;
                Colour[i * 4 + 1] = background;
                Colour[i * 4 + 2] = background;
                Colour[i * 4 + 3] = 255;
            }
        }

        public bool DepthTest(int x, int y, float depth)
        {
            if (x < 0 || y < 0 || x >= Width || y >= Height) return false;
            return depth < _depth[y * Width + x];
        }

        public void Plot(int x, int y, float depth, byte r, byte g, byte b)
        {
            if (x < 0 || y < 0 || x >= Width || y >= Height) return;
            int index = y * Width + x;
            _depth[index] = depth;
            Colour[index * 4] = r;
            Colour[index * 4 + 1] = g;
            Colour[index * 4 + 2] = b;
            Colour[index * 4 + 3] = 255;
        }

        public void PlotOver(int x, int y, byte r, byte g, byte b)
        {
            if (x < 0 || y < 0 || x >= Width || y >= Height) return;
            int index = y * Width + x;
            Colour[index * 4] = r;
            Colour[index * 4 + 1] = g;
            Colour[index * 4 + 2] = b;
            Colour[index * 4 + 3] = 255;
        }

        /// <summary>
        /// Source-over blend of a translucent fragment, without writing depth.
        /// </summary>
        /// <remarks>
        /// Leaving depth alone is what lets a second translucent surface behind this one still draw.
        /// It also means the result depends on draw order, which is why the translucent pass is
        /// sorted back to front.
        /// </remarks>
        public void Blend(int x, int y, byte r, byte g, byte b, float alpha)
        {
            if (x < 0 || y < 0 || x >= Width || y >= Height) return;
            int index = y * Width + x;
            float inverse = 1f - alpha;

            Colour[index * 4] = (byte)(r * alpha + Colour[index * 4] * inverse);
            Colour[index * 4 + 1] = (byte)(g * alpha + Colour[index * 4 + 1] * inverse);
            Colour[index * 4 + 2] = (byte)(b * alpha + Colour[index * 4 + 2] * inverse);
            Colour[index * 4 + 3] = 255;
        }
    }
}
