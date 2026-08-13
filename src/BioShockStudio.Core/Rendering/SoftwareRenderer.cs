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
        var projection = Perspective(
            camera.FieldOfView, (float)width / height,
            MathF.Max(0.0005f, MathF.Min(camera.Distance, radius) * 0.01f),
            (camera.Distance + radius) * 4f);
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
        var texture = options.Textured ? model.Texture : null;
        var normalMap = options.Shaded && options.Textured ? model.NormalMap : null;
        var specularMap = options.Shaded && options.Textured ? model.SpecularMap : null;

        // Alpha is taken from the diffuse texture rather than from the material's blend mode, whose
        // values are still UNKNOWN — see docs/research/materials.md. A texture whose alpha is 255
        // everywhere takes exactly the path it always did, so nothing opaque can change.
        bool hasAlpha = texture is not null && options.Transparency && texture.HasTransparency;

        // Opaque first, then the translucent surfaces back to front over the top. Without the sort a
        // window drawn before what is behind it hides it.
        var order = hasAlpha
            ? SortedTriangles(model, positions, camera.Eye)
            : null;

        for (int pass = 0; pass < (hasAlpha ? 2 : 1); pass++)
        {
            bool blendPass = pass == 1;
            int triangleCount = model.Indices.Count / 3;

            for (int t = 0; t < triangleCount; t++)
            {
                int i = (order is null ? t : order[t]) * 3;

                int a = model.Indices[i], b = model.Indices[i + 1], c = model.Indices[i + 2];
                if (a >= positions.Length || b >= positions.Length || c >= positions.Length) continue;

                if (!Project(positions[a], viewProjection, target, out var pa) ||
                    !Project(positions[b], viewProjection, target, out var pb) ||
                    !Project(positions[c], viewProjection, target, out var pc))
                {
                    continue;
                }

                RasteriseTriangle(target, pa, pb, pc, (bary, depth, x, y) =>
                {
                    var uv = model.Vertices[a].Uv * bary.X
                             + model.Vertices[b].Uv * bary.Y
                             + model.Vertices[c].Uv * bary.Z;

                    byte r, g, bl, alpha;
                    if (texture is not null) (r, g, bl, alpha) = SampleRgba(texture, uv);
                    else { r = g = bl = 190; alpha = 255; }

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
                });
            }
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
            var matrix = pose is null ? model.Bones[socket.Bone].RestGlobal : pose[socket.Bone];
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
        RenderTarget target, Projected a, Projected b, Projected c, Action<Vector3, float, int, int> shade)
    {
        float area = (b.X - a.X) * (c.Y - a.Y) - (b.Y - a.Y) * (c.X - a.X);
        if (MathF.Abs(area) < 1e-6f) return;

        int minX = Math.Max(0, (int)MathF.Floor(Math.Min(a.X, Math.Min(b.X, c.X))));
        int maxX = Math.Min(target.Width - 1, (int)MathF.Ceiling(Math.Max(a.X, Math.Max(b.X, c.X))));
        int minY = Math.Max(0, (int)MathF.Floor(Math.Min(a.Y, Math.Min(b.Y, c.Y))));
        int maxY = Math.Min(target.Height - 1, (int)MathF.Ceiling(Math.Max(a.Y, Math.Max(b.Y, c.Y))));

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

    private static (byte R, byte G, byte B, byte A) SampleRgba(PreviewImage texture, Vector2 uv)
    {
        // The game's V runs top-down, the same flip the exporters apply.
        int x = (int)(Wrap(uv.X) * (texture.Width - 1));
        int y = (int)(Wrap(uv.Y) * (texture.Height - 1));
        int offset = (y * texture.Width + x) * 4;

        if (offset < 0 || offset + 3 >= texture.Rgba.Length) return (190, 190, 190, 255);
        return (texture.Rgba[offset], texture.Rgba[offset + 1], texture.Rgba[offset + 2], texture.Rgba[offset + 3]);

        static float Wrap(float value)
        {
            value -= MathF.Floor(value);
            return value < 0f ? value + 1f : value;
        }
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
