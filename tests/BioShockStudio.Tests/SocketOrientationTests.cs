using System.Numerics;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Where a static prop actually lands on its socket bone.
/// <para>
/// A prop that is placed backwards points into the host instead of away from it, which hides it
/// inside the body and reads as "the attachment does not draw". This measures the direction rather
/// than relying on a render, because a buried prop looks identical to a missing one.
/// </para>
/// </summary>
[Collection(GameCollection.Name)]
public sealed class SocketOrientationTests(GameFixture game)
{
    private static readonly string LogPath =
        Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") ?? Path.Combine(Path.GetTempPath(), "socket.txt");

    private static void Log(string line) => File.AppendAllText(LogPath, line + Environment.NewLine);

    [RequiresGameFact]
    public void Print_StaticPropPlacement()
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is null) return;

        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        foreach (var (packageName, group) in new[]
                 {
                     ("1-Medical", "NewProtectorBouncer"),
                     ("7-Gauntlet", "ProtectorRosie"),
                 })
        {
            using var package = Core.Packages.BioShockPackage.Open(
                Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), packageName + ".bsm"));

            var entry = AssetCatalogService.Catalogue(package, packageName)
                .Where(e => e.Group == group && e.ClassName == "SkeletalMesh")
                .MaxBy(e => e.SerialSize);
            if (entry is null) { Log($"{group}: not found"); continue; }

            var preview = new MeshPreviewService(catalog);
            var host = preview.Load(entry).Model;
            var hostCentre = host.Centre;

            Log($"=== {group}: {host.Vertices.Count} verts, centre {Fmt(hostCentre)}, radius {host.Radius:0.#}");

            foreach (var attachment in new AssetContextService(catalog).Attachments(entry).Where(a => a.IsStatic))
            {
                int bone = -1;
                for (int i = 0; i < host.Bones.Count; i++)
                    if (string.Equals(host.Bones[i].Name, attachment.SocketBone, StringComparison.OrdinalIgnoreCase))
                        bone = i;

                if (bone < 0) { Log($"  {attachment.Socket}: bone '{attachment.SocketBone}' not on the skeleton"); continue; }

                var prop = preview.LoadAttachment(attachment).Model;
                if (!prop.HasGeometry) { Log($"  {attachment.Socket}: no geometry"); continue; }

                var transform = host.Bones[bone].RestGlobal;
                var origin = transform.Translation;

                // The prop's own long axis, and where it ends up.
                Vector3 lo = new(float.MaxValue), hi = new(float.MinValue);
                foreach (var v in prop.Vertices) { lo = Vector3.Min(lo, v.Position); hi = Vector3.Max(hi, v.Position); }
                var extent = hi - lo;
                var localCentre = (lo + hi) * 0.5f;

                var worldCentre = Vector3.Transform(localCentre, transform);
                var worldFar = Vector3.Transform(localCentre + LongAxis(extent) * extent.Length() * 0.5f, transform);

                // Does the prop point away from the host's body, or into it?
                float centreToBody = Vector3.Distance(worldCentre, hostCentre);
                float tipToBody = Vector3.Distance(worldFar, hostCentre);
                float socketToBody = Vector3.Distance(origin, hostCentre);

                Log($"  {attachment.Socket,-14} -> mesh {attachment.MeshObject,-24} bone {attachment.SocketBone,-22} {prop.Vertices.Count,6} verts");
                Log($"      prop extent {Fmt(extent)}  long axis {LongAxis(extent)}");
                Log($"      socket at {Fmt(origin)}  ({socketToBody:0.#} from body centre)");
                Log($"      prop centre {centreToBody:0.#} from body centre, far tip {tipToBody:0.#}  " +
                    $"=> points {(tipToBody > centreToBody ? "AWAY (correct)" : "INTO THE BODY (backwards)")}");

                // The decisive measure: a prop that is placed backwards ends up inside the host, and
                // a buried prop looks exactly like a missing one in a render.
                Log($"      buried: {Buried(prop, transform, host):P0} of its vertices are inside the host's hull" +
                    $"   |   with the socket's 180 deg removed: {Buried(prop, Unflip(transform), host):P0}");
            }
        }
    }

    /// <summary>What follows the socket table — looking for the per-socket transform.</summary>
    [RequiresGameFact]
    public void Print_WhatFollowsTheSocketTable()
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is null) return;

        using var package = Core.Packages.BioShockPackage.Open(
            Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));

        var entry = AssetCatalogService.Catalogue(package, "1-Medical")
            .Where(e => e.Group == "NewProtectorBouncer" && e.ClassName == "SkeletalMesh")
            .MaxBy(e => e.SerialSize)!;

        var export = package.Exports
            .Where(e => e.ObjectName == entry.Name && package.GetClassName(e) == "SkeletalMesh")
            .MaxBy(e => e.SerialSize)!;
        Log($"mesh export: {export.ObjectName}");

        byte[] payload = package.ReadExportData(export);
        var sockets = Core.Mesh.SkeletalMeshReader.ReadSockets(payload, package.Names);
        var (start, end, count) = Core.Mesh.SkeletalMeshReader.DescribeSocketTable(payload, package.Names);

        Log($"NewProtectorBouncer: payload {payload.Length} bytes, socket table {start}..{end} ({count} sockets)");
        foreach (var s in sockets) Log($"    {s.Name} -> {s.BoneName}");

        // If a per-socket transform is stored, it follows the two name arrays: for N sockets that
        // would be N * (3 floats location + 3 ints rotation) = N * 24 bytes.
        Log($"    expecting {count * 24} bytes if each socket carries an FVector + FRotator");
        Log($"    next 160 bytes: {Convert.ToHexString(payload.AsSpan(end, Math.Min(160, payload.Length - end)))}");

        // Read them as floats and as UE 16-bit angles so the shape is visible either way.
        for (int i = 0; i < Math.Min(count, 4); i++)
        {
            int at = end + i * 24;
            if (at + 24 > payload.Length) break;
            float fx = BitConverter.ToSingle(payload, at);
            float fy = BitConverter.ToSingle(payload, at + 4);
            float fz = BitConverter.ToSingle(payload, at + 8);
            int p = BitConverter.ToInt32(payload, at + 12);
            int y = BitConverter.ToInt32(payload, at + 16);
            int r = BitConverter.ToInt32(payload, at + 20);
            Log($"    [{i}] loc=({fx,10:0.##},{fy,10:0.##},{fz,10:0.##})  rot=({p},{y},{r})  " +
                $"= ({p * 360.0 / 65536:0.#},{y * 360.0 / 65536:0.#},{r * 360.0 / 65536:0.#}) deg");
        }
    }

    /// <summary>
    /// Fraction of a placed prop's vertices that fall inside the host's own vertex cloud, judged by
    /// a coarse occupancy grid. Crude, but it distinguishes "buried" from "sticking out" without
    /// needing a real containment test.
    /// </summary>
    private static float Buried(PreviewModel prop, Matrix4x4 transform, PreviewModel host)
    {
        Vector3 lo = new(float.MaxValue), hi = new(float.MinValue);
        foreach (var v in host.Vertices) { lo = Vector3.Min(lo, v.Position); hi = Vector3.Max(hi, v.Position); }

        const int n = 24;
        var size = hi - lo;
        var cell = new Vector3(MathF.Max(size.X, 1e-3f), MathF.Max(size.Y, 1e-3f), MathF.Max(size.Z, 1e-3f)) / n;
        var occupied = new HashSet<(int, int, int)>();

        foreach (var v in host.Vertices)
        {
            var g = (v.Position - lo) / cell;
            occupied.Add(((int)g.X, (int)g.Y, (int)g.Z));
        }

        int inside = 0, total = 0;
        foreach (var v in prop.Vertices)
        {
            var w = Vector3.Transform(v.Position, transform);
            var g = (w - lo) / cell;
            total++;
            if (occupied.Contains(((int)g.X, (int)g.Y, (int)g.Z))) inside++;
        }

        return total == 0 ? 0f : (float)inside / total;
    }

    /// <summary>The same placement with a 180 degree turn about the socket's own Y removed.</summary>
    private static Matrix4x4 Unflip(Matrix4x4 transform) =>
        Matrix4x4.CreateFromAxisAngle(Vector3.UnitY, MathF.PI) * transform;

    private static Vector3 LongAxis(Vector3 extent) =>
        extent.X >= extent.Y && extent.X >= extent.Z ? Vector3.UnitX
        : extent.Y >= extent.Z ? Vector3.UnitY
        : Vector3.UnitZ;

    private static string Fmt(Vector3 v) => $"({v.X,7:0.#},{v.Y,7:0.#},{v.Z,7:0.#})";
}
