using System.Numerics;

namespace BioShockStudio.Core.Export.Fbx;

/// <summary>Options for one FBX file. One file carries at most one animation take.</summary>
public sealed record FbxExportOptions
{
    /// <summary>
    /// Unit scale applied to every length. The game authors in centimetres and Unreal's unit is the
    /// centimetre, so the default is 1 and the exported numbers are the game's own.
    /// </summary>
    public float Scale { get; init; } = 1f;

    /// <summary>Include the skinned mesh, its skin deformer and the bind pose.</summary>
    public bool IncludeMesh { get; init; } = true;

    /// <summary>
    /// Write each socket as a null node parented to its bone.
    /// <para>
    /// Blender imports these as empties, which is what a socket should be. Unreal's skeletal mesh
    /// importer has not been tried and may take any node in the hierarchy as a bone, which would add
    /// nineteen junk bones to the hands skeleton — turn this off if that happens. The sockets are in
    /// the manifest either way.
    /// </para>
    /// </summary>
    public bool IncludeSocketNodes { get; init; } = true;

    /// <summary>Name of the single animation to bake as this file's take, or null for none.</summary>
    public string? Animation { get; init; }

    public string Creator { get; init; } = "BioShockStudio";

    /// <summary>
    /// Directory the FBX is written to. Texture paths in the scene are relative to it, and FBX wants
    /// an absolute path as well as a relative one, so it has to be known here.
    /// </summary>
    public string? BaseDirectory { get; init; }
}

/// <summary>
/// Turns an <see cref="AnimationScene"/> into the FBX object graph.
/// </summary>
/// <remarks>
/// The scene JSON is the project's intermediate representation and is already validated against the
/// game's own transforms, so this builder only re-expresses it: no geometry, weighting or timing
/// decision is taken here that the scene has not already made.
/// </remarks>
public static class FbxSceneBuilder
{
    /// <summary>Sockets are exported as null nodes under their bone; Unreal turns this prefix into a socket.</summary>
    public const string SocketPrefix = "SOCKET_";

    private const int KeyVersion = 4008;

    /// <summary>Constant/linear-ish key attributes, matching what Blender writes for baked curves.</summary>
    private const int KeyAttributeFlags = (1 << 2) | (1 << 8) | (1 << 13) | (1 << 14);

    private static readonly float[] KeyAttributeData = [0f, 0f, 9.419963346924634e-30f, 0f];

    /// <summary>
    /// Separates an object's name from its class inside the single string FBX stores for both. Built
    /// from character codes because the two bytes are a NUL and an SOH, not printable text.
    /// </summary>
    private static readonly string NameSeparator = new([(char)0, (char)1]);

    public static IReadOnlyList<FbxNode> Build(AnimationScene scene, FbxExportOptions options) =>
        new Builder(scene, options).Build();

    private sealed class Builder(AnimationScene scene, FbxExportOptions options)
    {
        private readonly List<FbxNode> _objects = [];
        private readonly List<FbxNode> _connections = [];
        private readonly Dictionary<string, int> _counts = [];
        private long _nextId = 1_000_000;

        private long[] _boneModels = [];
        private Matrix4x4[] _boneGlobals = [];
        private SceneAnimation? _take;

        public IReadOnlyList<FbxNode> Build()
        {
            _take = options.Animation is null
                ? null
                : scene.Animations.FirstOrDefault(a => string.Equals(a.Name, options.Animation, StringComparison.Ordinal))
                  ?? throw new ArgumentException($"The scene has no animation named '{options.Animation}'.");

            _boneGlobals = FbxMath.GlobalPose(scene.Bones, options.Scale);
            BuildSkeleton();

            long meshModel = options.IncludeMesh && scene.Mesh is not null ? BuildMesh(scene.Mesh) : 0;
            BuildSockets();
            BuildBindPose(meshModel);
            if (_take is not null) BuildTake(_take);

            return Assemble();
        }

        // ---------------------------------------------------------------- skeleton

        private void BuildSkeleton()
        {
            _boneModels = new long[scene.Bones.Count];

            for (int i = 0; i < scene.Bones.Count; i++)
            {
                var bone = scene.Bones[i];

                // Bone length is cosmetic in FBX, as it is in Blender, but a sensible value keeps the
                // rig readable in whatever opens the file.
                double size = 1.0;
                foreach (var child in scene.Bones)
                {
                    if (child.Parent != i) continue;
                    double candidate = new Vector3(child.Translation[0], child.Translation[1], child.Translation[2])
                        .Length() * options.Scale;
                    if (candidate > 0.001) { size = candidate; break; }
                }

                long attributeId = NewObject("NodeAttribute", "NodeAttribute", string.Empty, "LimbNode", out var attribute);
                Properties70(attribute).Property("Size", "double", "Number", string.Empty).Double(size);
                attribute.Add("TypeFlags", "Skeleton");

                long modelId = NewObject("Model", "Model", bone.Name, "LimbNode", out var model);
                _boneModels[i] = modelId;
                WriteNodeTransform(
                    model,
                    new Vector3(bone.Translation[0], bone.Translation[1], bone.Translation[2]) * options.Scale,
                    new Quaternion(bone.Rotation[0], bone.Rotation[1], bone.Rotation[2], bone.Rotation[3]),
                    new Vector3(bone.Scale[0], bone.Scale[1], bone.Scale[2]));

                Connect(attributeId, modelId);
                // Parent -1 means the skeleton root, which hangs off the document root node (id 0).
                Connect(modelId, bone.Parent < 0 ? 0 : _boneModels[bone.Parent]);
            }
        }

        private void WriteNodeTransform(FbxNode model, Vector3 translation, Quaternion rotation, Vector3 scale)
        {
            model.Add("Version", 232);
            var properties = Properties70(model);

            properties.Property("RotationActive", "bool", string.Empty, string.Empty).Int32(1);
            // eInheritRrSs: a child's world transform is the plain product of the chain, which is how
            // the game's reference pose and the scene JSON are composed.
            properties.Property("InheritType", "enum", string.Empty, string.Empty).Int32(0);
            properties.Property("DefaultAttributeIndex", "int", "Integer", string.Empty).Int32(0);

            var euler = FbxMath.ToEulerDegrees(rotation);
            properties.Property("Lcl Translation", "Lcl Translation", string.Empty, "A+")
                .Double(translation.X).Double(translation.Y).Double(translation.Z);
            properties.Property("Lcl Rotation", "Lcl Rotation", string.Empty, "A+")
                .Double(euler.X).Double(euler.Y).Double(euler.Z);
            properties.Property("Lcl Scaling", "Lcl Scaling", string.Empty, "A+")
                .Double(scale.X).Double(scale.Y).Double(scale.Z);

            model.Add("Shading").Bool(true);
            model.Add("Culling", "CullingOff");
        }

        // ---------------------------------------------------------------- mesh

        private long BuildMesh(SceneMesh mesh)
        {
            int vertexCount = mesh.Positions.Length / 3;
            string name = scene.SourceObject + "_Mesh";

            long geometryId = NewObject("Geometry", "Geometry", name, "Mesh", out var geometry);
            Properties70(geometry);
            geometry.Add("GeometryVersion", 124);

            var positions = new double[mesh.Positions.Length];
            for (int i = 0; i < positions.Length; i++) positions[i] = mesh.Positions[i] * options.Scale;
            geometry.Add("Vertices").DoubleArray(positions);

            // FBX marks the last corner of each polygon by bitwise complement, which is also how a
            // reader recovers the face size from a flat index list.
            var polygons = new int[mesh.Triangles.Length];
            for (int i = 0; i < mesh.Triangles.Length; i++)
                polygons[i] = i % 3 == 2 ? ~mesh.Triangles[i] : mesh.Triangles[i];
            geometry.Add("PolygonVertexIndex").Int32Array(polygons);

            // Normals are per vertex in the game data but are written per polygon vertex, the one
            // mapping every importer accepts without qualification.
            var normals = new double[mesh.Triangles.Length * 3];
            for (int i = 0; i < mesh.Triangles.Length; i++)
            {
                int v = mesh.Triangles[i];
                normals[i * 3] = mesh.Normals[v * 3];
                normals[i * 3 + 1] = mesh.Normals[v * 3 + 1];
                normals[i * 3 + 2] = mesh.Normals[v * 3 + 2];
            }
            var normalLayer = geometry.Add("LayerElementNormal").Int32(0);
            normalLayer.Add("Version", 101);
            normalLayer.Add("Name", string.Empty);
            normalLayer.Add("MappingInformationType", "ByPolygonVertex");
            normalLayer.Add("ReferenceInformationType", "Direct");
            normalLayer.Add("Normals").DoubleArray(normals);

            // The game's V axis runs top-down; FBX's runs bottom-up, the same flip the Blender
            // importer applies.
            var uvs = new double[vertexCount * 2];
            for (int i = 0; i < vertexCount; i++)
            {
                uvs[i * 2] = mesh.Uvs[i * 2];
                uvs[i * 2 + 1] = 1.0 - mesh.Uvs[i * 2 + 1];
            }
            var uvLayer = geometry.Add("LayerElementUV").Int32(0);
            uvLayer.Add("Version", 101);
            uvLayer.Add("Name", "UVMap");
            uvLayer.Add("MappingInformationType", "ByPolygonVertex");
            uvLayer.Add("ReferenceInformationType", "IndexToDirect");
            uvLayer.Add("UV").DoubleArray(uvs);
            uvLayer.Add("UVIndex").Int32Array(mesh.Triangles);

            var layer = geometry.Add("Layer").Int32(0);
            layer.Add("Version", 100);
            var normalEntry = layer.Add("LayerElement");
            normalEntry.Add("Type", "LayerElementNormal");
            normalEntry.Add("TypedIndex", 0);
            var uvEntry = layer.Add("LayerElement");
            uvEntry.Add("Type", "LayerElementUV");
            uvEntry.Add("TypedIndex", 0);

            // A mesh naming several materials draws a run of its index buffer with each, so the
            // assignment is per polygon. Where it names one, "AllSame" with a single entry says so
            // more cheaply and is what every importer takes the fast path on.
            //
            // A triangle whose slot resolved nothing is -1 in the scene. FBX has no "no material",
            // so it is given slot 0 and the untextured run is visible as the slot it landed in
            // rather than dropping the polygon.
            var assignment = mesh.TriangleMaterials;
            bool perPolygon = assignment.Length > 0 && scene.Materials.Count > 1;

            var materialLayer = geometry.Add("LayerElementMaterial").Int32(0);
            materialLayer.Add("Version", 101);
            materialLayer.Add("Name", string.Empty);
            materialLayer.Add("MappingInformationType", perPolygon ? "ByPolygon" : "AllSame");
            materialLayer.Add("ReferenceInformationType", "IndexToDirect");
            materialLayer.Add("Materials").Int32Array(
                perPolygon ? [.. assignment.Select(m => Math.Max(0, m))] : [0]);

            var materialEntry = layer.Add("LayerElement");
            materialEntry.Add("Type", "LayerElementMaterial");
            materialEntry.Add("TypedIndex", 0);

            long modelId = NewObject("Model", "Model", name, "Mesh", out var model);
            WriteNodeTransform(model, Vector3.Zero, Quaternion.Identity, Vector3.One);

            Connect(geometryId, modelId);
            Connect(modelId, 0);

            // A static mesh has no skeleton, so it gets no skin deformer at all rather than an empty
            // one an importer would have to interpret.
            if (scene.Bones.Count > 0) BuildSkin(mesh, geometryId, name);

            // Connection order is the slot order: LayerElementMaterial indexes the materials
            // attached to the model by the order they were connected, so these must go out in the
            // same order the scene lists them.
            foreach (var material in scene.Materials) BuildMaterial(material, modelId);

            return modelId;
        }

        private void BuildSkin(SceneMesh mesh, long geometryId, string name)
        {
            int vertexCount = mesh.Positions.Length / 3;

            var indexes = new List<int>[scene.Bones.Count];
            var weights = new List<double>[scene.Bones.Count];

            int cursor = 0;
            for (int vertex = 0; vertex < vertexCount; vertex++)
            {
                for (int i = 0; i < mesh.InfluenceCounts[vertex]; i++, cursor++)
                {
                    int bone = mesh.InfluenceBones[cursor];
                    if (bone < 0 || bone >= scene.Bones.Count) continue;
                    (indexes[bone] ??= []).Add(vertex);
                    (weights[bone] ??= []).Add(mesh.InfluenceWeights[cursor]);
                }
            }

            long skinId = NewObject("Deformer", "Deformer", name, "Skin", out var skin);
            skin.Add("Version", 101);
            skin.Add("Link_DeformAcuracy", 50.0);
            skin.Add("SkinningType", "Linear");
            Connect(skinId, geometryId);

            for (int bone = 0; bone < scene.Bones.Count; bone++)
            {
                if (indexes[bone] is null) continue;

                long clusterId = NewObject("Deformer", "SubDeformer", scene.Bones[bone].Name, "Cluster", out var cluster);
                cluster.Add("Version", 100);
                cluster.Add("UserData", string.Empty).String(string.Empty);
                cluster.Add("Indexes").Int32Array(CollectionsMarshalSpan(indexes[bone]));
                cluster.Add("Weights").DoubleArray(CollectionsMarshalSpan(weights[bone]));

                // The mesh sits at the origin in skeleton space, so its bind transform is the
                // identity and the cluster's bone-space Transform reduces to the inverse bind.
                Matrix4x4.Invert(_boneGlobals[bone], out var inverseBind);
                cluster.Add("Transform").MatrixArray(inverseBind);
                cluster.Add("TransformLink").MatrixArray(_boneGlobals[bone]);
                cluster.Add("TransformAssociateModel").MatrixArray(Matrix4x4.Identity);

                Connect(clusterId, skinId);
                Connect(_boneModels[bone], clusterId);
            }
        }

        // ---------------------------------------------------------------- material

        /// <summary>
        /// Writes the material and its texture bindings.
        /// </summary>
        /// <remarks>
        /// Textures travel as file references rather than embedded data, because the exporter already
        /// writes the PNGs beside the FBX and an importer that can read the FBX can read those. The
        /// relative path is what makes the export portable; the absolute one is what several
        /// importers actually look at first, so both are written.
        /// </remarks>
        private void BuildMaterial(SceneMaterial material, long meshModel)
        {
            long materialId = NewObject("Material", "Material", material.Name, string.Empty, out var node);
            node.Add("Version", 102);
            node.Add("ShadingModel", "phong");
            node.Add("MultiLayer", 0);

            var properties = Properties70(node);
            var diffuse = material.DiffuseColor ?? [1f, 1f, 1f, 1f];
            properties.Property("DiffuseColor", "Color", "", "A")
                .Double(diffuse[0]).Double(diffuse[1]).Double(diffuse[2]);
            if (material.SpecularColor is { Length: >= 3 } specular)
            {
                properties.Property("SpecularColor", "Color", "", "A")
                    .Double(specular[0]).Double(specular[1]).Double(specular[2]);
            }
            // The game's Glossiness runs well past 1 — 271 on one of the shipped shaders — so it is
            // carried through unchanged rather than remapped into a range this exporter guessed at.
            if (material.Glossiness is { } glossiness)
                properties.Property("Shininess", "double", "Number", "A").Double(glossiness);
            if (material.SpecularBrightness is { } brightness)
                properties.Property("SpecularFactor", "double", "Number", "A").Double(brightness);

            Connect(materialId, meshModel);

            // FBX names the slots after its own phong model, not after the game's shader properties.
            BuildTexture(material.Diffuse, materialId, "DiffuseColor");
            BuildTexture(material.NormalMap, materialId, "NormalMap");
            BuildTexture(material.Specular, materialId, "SpecularColor");
        }

        private void BuildTexture(string? file, long materialId, string property)
        {
            if (file is null) return;

            string name = Path.GetFileNameWithoutExtension(file);
            string absolute = Path
                .GetFullPath(options.BaseDirectory is null ? file : Path.Combine(options.BaseDirectory, file))
                .Replace(Path.DirectorySeparatorChar, '/');

            long videoId = NewObject("Video", "Video", name, "Clip", out var video);
            Properties70(video).Property("Path", "KString", "XRefUrl", string.Empty).String(absolute);
            video.Add("UseMipMap", 0);
            video.Add("Filename", absolute);
            video.Add("RelativeFilename", file);

            long textureId = NewObject("Texture", "Texture", name, string.Empty, out var texture);
            texture.Add("Type", "TextureVideoClip");
            texture.Add("Version", 202);
            texture.Add("TextureName", name + NameSeparator + "Texture");

            var properties = Properties70(texture);
            properties.Property("UVSet", "KString", string.Empty, string.Empty).String("UVMap");
            properties.Property("UseMaterial", "bool", string.Empty, string.Empty).Int32(1);

            texture.Add("Media", name + NameSeparator + "Video");
            texture.Add("FileName", absolute);
            texture.Add("RelativeFilename", file);
            texture.Add("ModelUVTranslation").Double(0.0).Double(0.0);
            texture.Add("ModelUVScaling").Double(1.0).Double(1.0);
            texture.Add("Texture_Alpha_Source", "None");
            texture.Add("Cropping").Int32(0).Int32(0).Int32(0).Int32(0);

            Connect(videoId, textureId);
            ConnectProperty(textureId, materialId, property);
        }

        // ---------------------------------------------------------------- sockets and bind pose

        private void BuildSockets()
        {
            if (!options.IncludeSocketNodes) return;

            foreach (var socket in scene.Sockets)
            {
                // The mesh writes "R_Grip" where the skeleton writes "R_grip"; the format is
                // inconsistent about case, so the lookup has to be.
                int bone = IndexOfBone(socket.BoneName);
                if (bone < 0) continue;

                long attributeId = NewObject("NodeAttribute", "NodeAttribute", string.Empty, "Null", out var attribute);
                Properties70(attribute);
                attribute.Add("TypeFlags", "Null");

                long modelId = NewObject("Model", "Model", SocketPrefix + socket.Name, "Null", out var model);
                WriteNodeTransform(model, Vector3.Zero, Quaternion.Identity, Vector3.One);

                Connect(attributeId, modelId);
                Connect(modelId, _boneModels[bone]);
            }
        }

        private void BuildBindPose(long meshModel)
        {
            long poseId = NewObject("Pose", "Pose", scene.SourceObject, "BindPose", out var pose);
            pose.Add("Type", "BindPose");
            pose.Add("Version", 100);
            pose.Add("NbPoseNodes", scene.Bones.Count + (meshModel == 0 ? 0 : 1));

            if (meshModel != 0)
            {
                var entry = pose.Add("PoseNode");
                entry.Add("Node", meshModel);
                entry.Add("Matrix").MatrixArray(Matrix4x4.Identity);
            }

            for (int i = 0; i < scene.Bones.Count; i++)
            {
                var entry = pose.Add("PoseNode");
                entry.Add("Node", _boneModels[i]);
                entry.Add("Matrix").MatrixArray(_boneGlobals[i]);
            }
        }

        // ---------------------------------------------------------------- animation

        private void BuildTake(SceneAnimation animation)
        {
            long stop = FbxMath.ToTicks(animation.Duration);

            long stackId = NewObject("AnimationStack", "AnimStack", animation.Name, string.Empty, out var stack);
            var stackProperties = Properties70(stack);
            stackProperties.Property("LocalStart", "KTime", "Time", string.Empty).Int64(0);
            stackProperties.Property("LocalStop", "KTime", "Time", string.Empty).Int64(stop);
            stackProperties.Property("ReferenceStart", "KTime", "Time", string.Empty).Int64(0);
            stackProperties.Property("ReferenceStop", "KTime", "Time", string.Empty).Int64(stop);

            long layerId = NewObject("AnimationLayer", "AnimLayer", "BaseLayer", string.Empty, out _);
            Connect(layerId, stackId);

            var times = new long[animation.FrameCount];
            for (int frame = 0; frame < animation.FrameCount; frame++)
                times[frame] = FbxMath.ToTicks((double)frame * animation.FrameDuration);

            foreach (var track in animation.Tracks)
            {
                if (track.BoneIndex < 0 || track.BoneIndex >= scene.Bones.Count) continue;
                long model = _boneModels[track.BoneIndex];

                var translations = new float[animation.FrameCount * 3];
                var rotations = new float[animation.FrameCount * 3];
                var scales = new float[animation.FrameCount * 3];

                var previous = Vector3.Zero;
                for (int frame = 0; frame < animation.FrameCount; frame++)
                {
                    translations[frame * 3] = track.Translations[frame * 3] * options.Scale;
                    translations[frame * 3 + 1] = track.Translations[frame * 3 + 1] * options.Scale;
                    translations[frame * 3 + 2] = track.Translations[frame * 3 + 2] * options.Scale;

                    var euler = FbxMath.ToEulerDegrees(new Quaternion(
                        track.Rotations[frame * 4], track.Rotations[frame * 4 + 1],
                        track.Rotations[frame * 4 + 2], track.Rotations[frame * 4 + 3]));
                    if (frame > 0) euler = FbxMath.MakeCompatible(previous, euler);
                    previous = euler;

                    rotations[frame * 3] = euler.X;
                    rotations[frame * 3 + 1] = euler.Y;
                    rotations[frame * 3 + 2] = euler.Z;

                    scales[frame * 3] = track.Scales[frame * 3];
                    scales[frame * 3 + 1] = track.Scales[frame * 3 + 1];
                    scales[frame * 3 + 2] = track.Scales[frame * 3 + 2];
                }

                BuildCurveNode(layerId, model, "T", "Lcl Translation", times, translations);
                BuildCurveNode(layerId, model, "R", "Lcl Rotation", times, rotations);
                BuildCurveNode(layerId, model, "S", "Lcl Scaling", times, scales);
            }
        }

        /// <summary>
        /// Writes one animated property of one node: a curve node holding the property's default and
        /// one curve per component.
        /// </summary>
        private void BuildCurveNode(long layerId, long model, string name, string property, long[] times, float[] values)
        {
            long nodeId = NewObject("AnimationCurveNode", "AnimCurveNode", name, string.Empty, out var curveNode);
            var properties = Properties70(curveNode);

            string[] components = ["d|X", "d|Y", "d|Z"];
            for (int axis = 0; axis < 3; axis++)
                properties.Property(components[axis], "Number", string.Empty, "A").Double(values[axis]);

            Connect(nodeId, layerId);
            ConnectProperty(nodeId, model, property);

            for (int axis = 0; axis < 3; axis++)
            {
                var samples = new float[times.Length];
                for (int frame = 0; frame < times.Length; frame++) samples[frame] = values[frame * 3 + axis];

                long curveId = NewObject("AnimationCurve", "AnimCurve", string.Empty, string.Empty, out var curve);
                curve.Add("Default", (double)samples[0]);
                curve.Add("KeyVer", KeyVersion);
                curve.Add("KeyTime").Int64Array(times);
                curve.Add("KeyValueFloat").FloatArray(samples);
                curve.Add("KeyAttrFlags").Int32Array([KeyAttributeFlags]);
                curve.Add("KeyAttrDataFloat").FloatArray(KeyAttributeData);
                curve.Add("KeyAttrRefCount").Int32Array([times.Length]);

                ConnectProperty(curveId, nodeId, components[axis]);
            }
        }

        // ---------------------------------------------------------------- assembly

        private IReadOnlyList<FbxNode> Assemble()
        {
            var roots = new List<FbxNode>();

            var header = new FbxNode("FBXHeaderExtension");
            header.Add("FBXHeaderVersion", 1003);
            header.Add("FBXVersion", FbxWriter.Version);
            header.Add("EncryptionType", 0);
            var timestamp = header.Add("CreationTimeStamp");
            timestamp.Add("Version", 1000);
            // A fixed timestamp keeps the output byte-for-byte reproducible, which is what lets a
            // test assert on the file rather than only on its parse.
            timestamp.Add("Year", 1970);
            timestamp.Add("Month", 1);
            timestamp.Add("Day", 1);
            timestamp.Add("Hour", 0);
            timestamp.Add("Minute", 0);
            timestamp.Add("Second", 0);
            timestamp.Add("Millisecond", 0);
            header.Add("Creator", options.Creator);
            roots.Add(header);

            roots.Add(new FbxNode("FileId").Bytes(
                [0x28, 0xB3, 0x2A, 0xEB, 0xB6, 0x24, 0xCC, 0xC2, 0xBF, 0xC8, 0xB0, 0x2A, 0xA9, 0x2B, 0xFC, 0xF1]));
            roots.Add(new FbxNode("CreationTime").String("1970-01-01 00:00:00:000"));
            roots.Add(new FbxNode("Creator").String(options.Creator));

            roots.Add(BuildGlobalSettings());

            var documents = new FbxNode("Documents");
            documents.Add("Count", 1);
            var document = documents.Add("Document").Int64(1).String(string.Empty).String("Scene");
            var documentProperties = Properties70(document);
            documentProperties.Property("SourceObject", "object", string.Empty, string.Empty);
            documentProperties.Property("ActiveAnimStackName", "KString", string.Empty, string.Empty)
                .String(_take?.Name ?? string.Empty);
            document.Add("RootNode", 0L);
            roots.Add(documents);

            roots.Add(new FbxNode("References"));

            var definitions = new FbxNode("Definitions");
            definitions.Add("Version", 100);
            definitions.Add("Count", _counts.Values.Sum() + 1);
            definitions.Add("ObjectType", "GlobalSettings").Add("Count", 1);
            foreach (var (type, count) in _counts.OrderBy(p => p.Key, StringComparer.Ordinal))
                definitions.Add("ObjectType", type).Add("Count", count);
            roots.Add(definitions);

            var objects = new FbxNode("Objects");
            objects.Children.AddRange(_objects);
            roots.Add(objects);

            var connections = new FbxNode("Connections");
            connections.Children.AddRange(_connections);
            roots.Add(connections);

            var takes = new FbxNode("Takes");
            takes.Add("Current", _take?.Name ?? string.Empty);
            roots.Add(takes);

            return roots;
        }

        private FbxNode BuildGlobalSettings()
        {
            var settings = new FbxNode("GlobalSettings");
            settings.Add("Version", 1000);
            var properties = Properties70(settings);

            // Z up, -Y forward, X right: the game's own convention and Unreal's.
            properties.Property("UpAxis", "int", "Integer", string.Empty).Int32(2);
            properties.Property("UpAxisSign", "int", "Integer", string.Empty).Int32(1);
            properties.Property("FrontAxis", "int", "Integer", string.Empty).Int32(1);
            properties.Property("FrontAxisSign", "int", "Integer", string.Empty).Int32(-1);
            properties.Property("CoordAxis", "int", "Integer", string.Empty).Int32(0);
            properties.Property("CoordAxisSign", "int", "Integer", string.Empty).Int32(1);
            properties.Property("OriginalUpAxis", "int", "Integer", string.Empty).Int32(2);
            properties.Property("OriginalUpAxisSign", "int", "Integer", string.Empty).Int32(1);
            properties.Property("UnitScaleFactor", "double", "Number", string.Empty).Double(1.0);
            properties.Property("OriginalUnitScaleFactor", "double", "Number", string.Empty).Double(1.0);
            properties.Property("TimeSpanStart", "KTime", "Time", string.Empty).Int64(0);
            properties.Property("TimeSpanStop", "KTime", "Time", string.Empty)
                .Int64(_take is null ? FbxMath.TimeUnit : FbxMath.ToTicks(_take.Duration));

            // The shipped animations are authored at rates that are not standard and not even equal
            // to each other — 30.00, 29.94 and 27.02 all occur in the pistol set — so the file
            // declares a custom rate rather than being resampled onto a nominal one.
            properties.Property("TimeMode", "enum", string.Empty, string.Empty).Int32(14);
            properties.Property("CustomFrameRate", "double", "Number", string.Empty)
                .Double(_take is null || _take.FrameDuration <= 0f ? 30.0 : 1.0 / _take.FrameDuration);

            return settings;
        }

        // ---------------------------------------------------------------- primitives

        private long NewObject(string record, string className, string name, string subclass, out FbxNode node)
        {
            long id = _nextId++;
            // Binary FBX object names embed their class after a null-then-one separator.
            node = new FbxNode(record).Int64(id).String(name + NameSeparator + className).String(subclass);
            _objects.Add(node);
            _counts[record] = _counts.GetValueOrDefault(record) + 1;
            return id;
        }

        private void Connect(long child, long parent) =>
            _connections.Add(new FbxNode("C").String("OO").Int64(child).Int64(parent));

        private void ConnectProperty(long child, long parent, string property) =>
            _connections.Add(new FbxNode("C").String("OP").Int64(child).Int64(parent).String(property));

        private int IndexOfBone(string name)
        {
            for (int i = 0; i < scene.Bones.Count; i++)
                if (string.Equals(scene.Bones[i].Name, name, StringComparison.OrdinalIgnoreCase)) return i;
            return -1;
        }

        private static FbxNode Properties70(FbxNode owner) => owner.Add("Properties70");

        private static ReadOnlySpan<int> CollectionsMarshalSpan(List<int> values) =>
            System.Runtime.InteropServices.CollectionsMarshal.AsSpan(values);

        private static ReadOnlySpan<double> CollectionsMarshalSpan(List<double> values) =>
            System.Runtime.InteropServices.CollectionsMarshal.AsSpan(values);
    }
}

internal static class FbxPropertyExtensions
{
    /// <summary>Adds a <c>P</c> record — one entry of a Properties70 block — and returns it for values.</summary>
    public static FbxNode Property(this FbxNode properties, string name, string type, string subType, string flags) =>
        properties.Add("P").String(name).String(type).String(subType).String(flags);
}
