using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Every property a shipped <c>StaticMesh</c> declares, censused across the game.
/// </summary>
/// <remarks>
/// <para>
/// <b>Written to answer Gate 1 item 1's "socket metadata", and the answer is that there is none.</b>
/// A static mesh declares no socket table of any kind: no <c>AttachAliases</c>, no
/// <c>AttachBoneNames</c>, no <c>AttachCoords</c>. The socket relationship runs the other way — a
/// static mesh <i>hangs off</i> a skeletal mesh's socket, which is decoded already
/// (<c>docs/research/skeletalmesh.md</c>, and <c>docs/HANDOFF.md</c> §6.6b for the transforms). The
/// item's phrase invited a search for something the container does not have.
/// </para>
/// <para>
/// <b>What it does declare is collision <i>intent</i>, and that is the more useful finding.</b> The
/// same item defers decoding the opaque kDOP tail "until a concrete UE5 target is known" — but the
/// game states what it wants from collision in plain properties: <c>NeverCollide</c> on 954 meshes,
/// <c>UseSimpleBoxCollision</c>, <c>UseSimpleVisionCollision</c>, <c>UseSimpleFootIKCollision</c>,
/// and <c>HavokCollisionTypeStatic</c>/<c>Dynamic</c>. A UE5 bridge wanting collision can carry that
/// across without decoding a kDOP tree at all, which makes the deferral cheaper than it looked.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class StaticMeshPropertyTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void NoStaticMeshDeclaresASocketTable()
    {
        var names = new Dictionary<string, int>(StringComparer.Ordinal);
        int meshes = 0;

        foreach (string file in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(file);

            foreach (var export in package.Exports)
            {
                if (package.GetClassName(export) != "StaticMesh") continue;

                byte[] payload;
                try { payload = package.ReadExportData(export); }
                catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }

                IReadOnlyList<UnrealProperty> properties;
                try { properties = UnrealPropertyReader.Read(payload, package.Names, out _); }
                catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }

                meshes++;
                foreach (var property in properties)
                    names[property.Name] = names.GetValueOrDefault(property.Name) + 1;
            }
        }

        Log($"{meshes:N0} StaticMesh exports walked; distinct property names:");
        foreach (var (name, count) in names.OrderByDescending(p => p.Value))
            Log($"    {name,-32} {count,6:N0}");

        Assert.True(meshes > 8_000, $"only {meshes} StaticMesh exports were walked");

        // Every static mesh names its materials — the property the reader depends on.
        Assert.Equal(meshes, names.GetValueOrDefault("Materials"));

        // The answer to "socket metadata": there is none, on any mesh in the game.
        foreach (string socket in new[] { "AttachAliases", "AttachBoneNames", "AttachCoords", "Sockets" })
            Assert.False(names.ContainsKey(socket),
                $"a static mesh declares {socket}, so this container does carry sockets after all");

        // Collision intent IS declared, and is what a UE5 bridge would use instead of the kDOP tree.
        // Asserted so the claim in this class's remarks cannot rot.
        Assert.True(names.ContainsKey("NeverCollide"), "no mesh declares NeverCollide");
        Assert.Contains(names.Keys, key => key.StartsWith("HavokCollisionType", StringComparison.Ordinal));
    }
}
