using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Runtime.InteropServices;
using Avalonia;
using Avalonia.OpenGL;
using Avalonia.OpenGL.Controls;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using static Avalonia.OpenGL.GlConsts;

namespace BioShockStudio.App.Views;

/// <summary>
/// The level viewport, drawn by the GPU.
/// </summary>
/// <remarks>
/// <para>
/// <b>Why this exists.</b> The CPU rasteriser draws a level at roughly two frames a second — 1.6 s
/// for all of <c>0-Lighthouse</c>, and still ~570 ms with a triangle budget and half resolution
/// (<c>LevelViewportPerformanceTests</c>). That is navigable and not pleasant. The geometry is
/// static and the same every frame, which is exactly what a GPU is for: upload once, draw many.
/// </para>
/// <para>
/// <b>It degrades to the software path rather than failing.</b> Every step that can fail — context
/// creation, shader compilation, buffer upload — is caught, and <see cref="Failed"/> is set with
/// the reason so the window can fall back and <i>say</i> that it did. A viewport that silently
/// shows nothing is worse than a slow one.
/// </para>
/// <para>
/// <b>This is the one part of the render path that no test covers.</b> Avalonia's headless renderer
/// has no GL context, so this cannot be exercised the way everything else in the project is. That
/// is why the software path is kept rather than replaced: it is the tested one, it produces the
/// snapshots, and both consume the same <see cref="LevelViewport"/> selection and the same
/// <see cref="GhostCamera"/> — so what the GPU draws is the same scene, drawn faster.
/// </para>
/// </remarks>
public sealed class LevelGlViewport : OpenGlControlBase
{
    /// <summary>Position, normal, UV.</summary>
    private const int FloatsPerVertex = 8;

    /// <summary>
    /// Enumerants Avalonia's <c>GlConsts</c> does not carry, at their values from the OpenGL
    /// registry. They are the same in desktop GL and GLES, which is what makes hardcoding them safe
    /// — these numbers have not changed since OpenGL 1.1.
    /// </summary>
    private const int GlLequal = 0x0203;
    private const int GlUnsignedInt = 0x1405;
    private const int GlTextureWrapS = 0x2802;
    private const int GlTextureWrapT = 0x2803;
    private const int GlRepeat = 0x2901;

    private sealed record Batch(
        int Vao, int Vbo, int Ebo, int IndexCount,
        List<(int First, int Count, int Texture, bool IsEffect)> Runs);

    private readonly Dictionary<PreviewModel, Batch> _batches = [];
    private readonly Dictionary<PreviewImage, int> _textures = [];

    private int _program;
    private int _mvpUniform;
    private int _modelUniform;
    private int _texturedUniform;
    private int _white;

    private PreparedLevel? _level;
    private GhostCamera _camera = new();
    private bool _uploaded;

    /// <summary>Why the GPU path is unusable, or null while it is working.</summary>
    public string? Failed { get; private set; }

    /// <summary>What the last frame drew, for the status line.</summary>
    public LevelViewport.Selection? LastSelection { get; private set; }

    public int TriangleBudget { get; set; } = 1_500_000;

    /// <summary>What to draw. Shared with the software path so the two cannot disagree.</summary>
    public LevelViewFilter Filter { get; set; } = new();

    public void Show(PreparedLevel level, GhostCamera camera)
    {
        _level = level;
        _camera = camera;
        _uploaded = false;
        RequestNextFrameRendering();
    }

    public void Move(GhostCamera camera)
    {
        _camera = camera;
        RequestNextFrameRendering();
    }

    public void Clear()
    {
        _level = null;
        _uploaded = false;
        RequestNextFrameRendering();
    }

    protected override void OnOpenGlInit(GlInterface gl)
    {
        try
        {
            // Avalonia hands back either desktop GL or GLES, and the shader preamble differs. Asking
            // the context rather than assuming is what keeps this working on both.
            bool es = GlVersion.Type == GlProfileType.OpenGLES;
            string header = es ? "#version 300 es\nprecision mediump float;\n" : "#version 330 core\n";

            int vertex = Compile(gl, GL_VERTEX_SHADER, header + VertexSource);
            int fragment = Compile(gl, GL_FRAGMENT_SHADER, header + FragmentSource);

            _program = gl.CreateProgram();
            gl.AttachShader(_program, vertex);
            gl.AttachShader(_program, fragment);
            gl.BindAttribLocationString(_program, 0, "aPosition");
            gl.BindAttribLocationString(_program, 1, "aNormal");
            gl.BindAttribLocationString(_program, 2, "aUv");

            string? link = gl.LinkProgramAndGetError(_program);
            if (link is not null) throw new InvalidOperationException("linking the shader failed: " + link);

            gl.DeleteShader(vertex);
            gl.DeleteShader(fragment);

            _mvpUniform = gl.GetUniformLocationString(_program, "uMvp");
            _modelUniform = gl.GetUniformLocationString(_program, "uModel");
            _texturedUniform = gl.GetUniformLocationString(_program, "uTextured");

            _white = CreateWhiteTexture(gl);
        }
        catch (Exception ex)
        {
            Failed = ex.Message;
        }
    }

    private static int Compile(GlInterface gl, int type, string source)
    {
        int shader = gl.CreateShader(type);
        string? error = gl.CompileShaderAndGetError(shader, source);
        if (error is not null) throw new InvalidOperationException("compiling a shader failed: " + error);
        return shader;
    }

    protected override void OnOpenGlDeinit(GlInterface gl)
    {
        foreach (var batch in _batches.Values)
        {
            gl.DeleteVertexArray(batch.Vao);
            gl.DeleteBuffer(batch.Vbo);
            gl.DeleteBuffer(batch.Ebo);
        }
        _batches.Clear();

        foreach (int texture in _textures.Values) DeleteTexture(gl, texture);
        _textures.Clear();

        if (_white != 0) { DeleteTexture(gl, _white); _white = 0; }
        if (_program != 0) { gl.DeleteProgram(_program); _program = 0; }
    }

    protected override void OnOpenGlRender(GlInterface gl, int fb)
    {
        int width = Math.Max(1, (int)(Bounds.Width * VisualRoot!.RenderScaling));
        int height = Math.Max(1, (int)(Bounds.Height * VisualRoot.RenderScaling));

        gl.Viewport(0, 0, width, height);
        gl.ClearColor(0.125f, 0.125f, 0.125f, 1f);
        gl.Clear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        if (Failed is not null || _level is not { } level) return;

        try
        {
            if (!_uploaded) { Upload(gl, level); _uploaded = true; }

            gl.Enable(GL_DEPTH_TEST);
            gl.DepthFunc(GlLequal);
            gl.Enable(GL_CULL_FACE);
            gl.UseProgram(_program);

            var view = _camera.ToPreviewCamera();
            var mvp =
                Matrix4x4.CreateLookAt(view.Eye, view.Target, Vector3.UnitZ)
                * Matrix4x4.CreatePerspectiveFieldOfView(
                    view.FieldOfView, (float)width / height,
                    view.NearPlane ?? 4f, view.FarPlane ?? 400_000f);

            // The budget here is far larger than the software path's, because the cost that made
            // one necessary is not the cost the GPU pays. Culling is kept: it is nearly free and it
            // still removes most of a map.
            var selection = level.Viewport.Select(_camera, (float)width / height, TriangleBudget, Filter);
            LastSelection = selection;

            foreach (var instance in selection.Instances)
            {
                if (!_batches.TryGetValue(instance.Model, out var batch)) continue;

                var model = instance.Transform;
                Upload(gl, _mvpUniform, model * mvp);
                Upload(gl, _modelUniform, model);

                gl.BindVertexArray(batch.Vao);

                foreach (var (first, count, texture, isEffect) in batch.Runs)
                {
                    // Light shafts and glow cards: no base colour, meant to be blended additively.
                    // Drawn as surfaces they are opaque white sheets across the view.
                    if (isEffect && !Filter.ShowEffects) continue;

                    gl.ActiveTexture(GL_TEXTURE0);
                    gl.BindTexture(GL_TEXTURE_2D, texture == 0 ? _white : texture);
                    gl.Uniform1f(_texturedUniform, texture == 0 ? 0f : 1f);
                    gl.DrawElements(GL_TRIANGLES, count, GlUnsignedInt, new IntPtr(first * sizeof(uint)));
                }
            }

            gl.BindVertexArray(0);
        }
        catch (Exception ex)
        {
            Failed = ex.Message;
        }
    }

    /// <summary>
    /// Uploads a matrix.
    /// </summary>
    /// <remarks>
    /// <b>No transpose, and the shader multiplies <c>M * v</c>.</b> System.Numerics stores rows
    /// contiguously and uses the row-vector convention (<c>v * M</c>); OpenGL with
    /// <c>transpose = false</c> reads the same bytes as columns, so it sees Mᵀ — and
    /// <c>Mᵀ · v</c> is exactly <c>v · M</c>. Transposing here as well would apply the inverse
    /// convention twice and put the whole level inside out, which is the sort of thing that looks
    /// like a camera bug for an hour.
    /// </remarks>
    private static unsafe void Upload(GlInterface gl, int uniform, Matrix4x4 matrix)
    {
        if (uniform < 0) return;
        gl.UniformMatrix4fv(uniform, 1, false, &matrix);
    }

    private void Upload(GlInterface gl, PreparedLevel level)
    {
        foreach (var item in level.Viewport.Items)
        {
            if (_batches.ContainsKey(item.Model)) continue;
            _batches[item.Model] = Build(gl, item.Model);
        }
    }

    private Batch Build(GlInterface gl, PreviewModel model)
    {
        var vertices = new float[model.Vertices.Count * FloatsPerVertex];
        for (int i = 0; i < model.Vertices.Count; i++)
        {
            var vertex = model.Vertices[i];
            int at = i * FloatsPerVertex;
            vertices[at + 0] = vertex.Position.X;
            vertices[at + 1] = vertex.Position.Y;
            vertices[at + 2] = vertex.Position.Z;
            vertices[at + 3] = vertex.Normal.X;
            vertices[at + 4] = vertex.Normal.Y;
            vertices[at + 5] = vertex.Normal.Z;
            vertices[at + 6] = vertex.Uv.X;
            vertices[at + 7] = vertex.Uv.Y;
        }

        var indices = model.Indices.Select(i => (uint)i).ToArray();

        int vao = gl.GenVertexArray();
        gl.BindVertexArray(vao);

        int vbo = gl.GenBuffer();
        gl.BindBuffer(GL_ARRAY_BUFFER, vbo);
        Buffer(gl, GL_ARRAY_BUFFER, vertices);

        int ebo = gl.GenBuffer();
        gl.BindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
        Buffer(gl, GL_ELEMENT_ARRAY_BUFFER, indices);

        const int stride = FloatsPerVertex * sizeof(float);
        gl.VertexAttribPointer(0, 3, GL_FLOAT, 0, stride, IntPtr.Zero);
        gl.EnableVertexAttribArray(0);
        gl.VertexAttribPointer(1, 3, GL_FLOAT, 0, stride, new IntPtr(3 * sizeof(float)));
        gl.EnableVertexAttribArray(1);
        gl.VertexAttribPointer(2, 2, GL_FLOAT, 0, stride, new IntPtr(6 * sizeof(float)));
        gl.EnableVertexAttribArray(2);

        gl.BindVertexArray(0);

        // One draw per surface, so a mesh with several materials draws with all of them rather than
        // with its first — the same rule MeshSurfaceResolver enforces everywhere else.
        var runs = new List<(int, int, int, bool)>();
        foreach (var surface in model.Surfaces)
        {
            int texture = surface.Texture is null ? 0 : Texture(gl, surface.Texture);
            runs.Add((surface.FirstIndex, surface.IndexCount, texture, surface.IsEffect));
        }
        if (runs.Count == 0) runs.Add((0, indices.Length, 0, false));

        return new Batch(vao, vbo, ebo, indices.Length, runs);
    }

    private static unsafe void Buffer(GlInterface gl, int target, float[] data)
    {
        fixed (float* pointer = data)
            gl.BufferData(target, new IntPtr(data.Length * sizeof(float)), new IntPtr(pointer), GL_STATIC_DRAW);
    }

    private static unsafe void Buffer(GlInterface gl, int target, uint[] data)
    {
        fixed (uint* pointer = data)
            gl.BufferData(target, new IntPtr(data.Length * sizeof(uint)), new IntPtr(pointer), GL_STATIC_DRAW);
    }

    private int Texture(GlInterface gl, PreviewImage image)
    {
        if (_textures.TryGetValue(image, out int existing)) return existing;

        int texture = gl.GenTexture();
        gl.BindTexture(GL_TEXTURE_2D, texture);

        unsafe
        {
            fixed (byte* pixels = image.Rgba)
            {
                gl.TexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image.Width, image.Height, 0,
                    GL_RGBA, GL_UNSIGNED_BYTE, new IntPtr(pixels));
            }
        }

        // No mipmaps: glGenerateMipmap is not among the functions Avalonia's GlInterface exposes,
        // and a level's textures are already capped at 256 by LevelViewportService, so the
        // minification this would smooth is limited. Distant surfaces shimmer a little as a result.
        gl.TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        gl.TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        gl.TexParameteri(GL_TEXTURE_2D, GlTextureWrapS, GlRepeat);
        gl.TexParameteri(GL_TEXTURE_2D, GlTextureWrapT, GlRepeat);

        return _textures[image] = texture;
    }

    /// <summary>A single white texel, so an untextured surface takes the same code path.</summary>
    private static unsafe int CreateWhiteTexture(GlInterface gl)
    {
        int texture = gl.GenTexture();
        gl.BindTexture(GL_TEXTURE_2D, texture);

        var pixel = new byte[] { 255, 255, 255, 255 };
        fixed (byte* pointer = pixel)
            gl.TexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, new IntPtr(pointer));

        gl.TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        gl.TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        return texture;
    }

    private static unsafe void DeleteTexture(GlInterface gl, int texture)
    {
        int handle = texture;
        gl.DeleteTextures(1, &handle);
    }

    private const string VertexSource = """
        in vec3 aPosition;
        in vec3 aNormal;
        in vec2 aUv;

        uniform mat4 uMvp;
        uniform mat4 uModel;

        out vec3 vNormal;
        out vec2 vUv;

        void main()
        {
            gl_Position = uMvp * vec4(aPosition, 1.0);
            vNormal = mat3(uModel) * aNormal;
            vUv = aUv;
        }
        """;

    /// <summary>
    /// Two fixed lights and a floor bounce, which is enough to read shape without pretending to be
    /// the game's lighting. The level's own lights are decoded but not applied: 465 of them in one
    /// map, and using them would be a lighting model this project has not verified against anything.
    /// </summary>
    private const string FragmentSource = """
        in vec3 vNormal;
        in vec2 vUv;

        uniform sampler2D uTexture;
        uniform float uTextured;

        out vec4 fragColour;

        void main()
        {
            vec4 albedo = texture(uTexture, vUv);

            // Cut out the holes. A great deal of BioShock's detail is a masked decal on a quad —
            // blood splatter, grime, posters, gratings — and the alpha channel is what makes the
            // quad invisible around the mark. Without this discard every one of them draws as an
            // opaque rectangle, which is what "blood splatters are bugged entirely" turned out to
            // be: the geometry and the texture were both correct and the shader ignored alpha.
            if (uTextured > 0.5 && albedo.a < 0.35) discard;

            vec3 normal = normalize(vNormal);
            float key = max(dot(normal, normalize(vec3(0.4, 0.6, 0.8))), 0.0);
            float fill = max(dot(normal, normalize(vec3(-0.5, -0.3, 0.2))), 0.0) * 0.35;
            float ambient = 0.35;

            vec3 base = mix(vec3(0.72), albedo.rgb, uTextured);

            fragColour = vec4(base * (ambient + key * 0.75 + fill), 1.0);
        }
        """;
}
