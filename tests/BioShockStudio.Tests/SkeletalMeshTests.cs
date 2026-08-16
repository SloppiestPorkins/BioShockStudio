using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class SkeletalMeshTests(GameFixture game)
{
    private (byte[] Payload, IReadOnlyList<NameEntry> Names) Load(string objectName)
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var export = package.Exports
            .Where(e => e.ObjectName == objectName && package.GetClassName(e) == "SkeletalMesh")
            .MaxBy(e => e.SerialSize)!;
        return (package.ReadExportData(export), package.Names);
    }

    [RequiresGameFact]
    public void HandsMesh_HeaderBoundsAreSane()
    {
        var (payload, _) = Load("NEWPlayerHands");
        var header = SkeletalMeshReader.ReadHeader(payload);

        Assert.True(header.BoundsValid);
        Assert.True(header.BoundsMin.X < header.BoundsMax.X);
        Assert.True(header.BoundsMin.Y < header.BoundsMax.Y);
        Assert.True(header.BoundsMin.Z < header.BoundsMax.Z);
        Assert.Equal(-16f, header.BoundsMin.X, 2);
        Assert.Equal(120f, header.BoundsMax.X, 2);
        Assert.True(header.SphereRadius > 0f);
        Assert.Equal(1f, header.Scale.X, 3);
    }

    [RequiresGameFact]
    public void HandsMesh_DeclaresWeaponSockets()
    {
        var (payload, names) = Load("NEWPlayerHands");
        var sockets = SkeletalMeshReader.ReadSockets(payload, names);

        Assert.Equal(19, sockets.Count);

        var byName = sockets.ToDictionary(s => s.Name, s => s.BoneName, StringComparer.Ordinal);

        // This is the mesh-side half of the weapon attachment story: every weapon socket resolves to
        // the R_Grip bone, which the hand skeleton also carries.
        Assert.Equal("R_Grip", byName["Pistol"]);
        Assert.Equal("R_Grip", byName["Wrench"]);
        Assert.Equal("R_Grip", byName["Launcher"]);
        Assert.Equal("R_Grip", byName["Crossbow"]);
        Assert.Equal("R_Grip", byName["TommyGun"]);

        // Plasmid and effect sockets hang off the left hand and the head instead.
        Assert.Equal("Bip01_L_Hand", byName["FirePlasmid"]);
        Assert.Equal("Bip01_L_Hand", byName["IceShards"]);
    }

    [RequiresGameFact]
    public void HandsMesh_SocketNamesCoverTheWeaponSet()
    {
        var (payload, names) = Load("NEWPlayerHands");
        var sockets = SkeletalMeshReader.ReadSockets(payload, names).Select(s => s.Name).ToHashSet(StringComparer.Ordinal);

        // The socket names line up with the per-weapon Havok animation sections.
        foreach (string weapon in new[] { "Wrench", "Pistol", "Crossbow", "TommyGun", "Chem" })
            Assert.Contains(weapon, sockets);
    }

    [RequiresGameFact]
    public void CharacterMesh_DeclaresItsOwnSockets()
    {
        var (payload, names) = Load("ProtectorRosie");
        var sockets = SkeletalMeshReader.ReadSockets(payload, names);

        var byName = sockets.ToDictionary(s => s.Name, s => s.BoneName, StringComparer.Ordinal);
        Assert.Contains("RivetGunSocket", byName.Keys);
        Assert.Contains("SmokeStack", byName.Keys);
    }

    [RequiresGameFact]
    public void EverySkeletalMesh_ReadsAHeaderWithoutThrowing()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var meshes = package.Exports.Where(e => package.GetClassName(e) == "SkeletalMesh").ToList();
        Assert.NotEmpty(meshes);

        var failures = new List<string>();
        foreach (var export in meshes)
        {
            if (export.SerialSize < 128) continue;
            try
            {
                var header = SkeletalMeshReader.ReadHeader(package.ReadExportData(export));
                if (!float.IsFinite(header.SphereRadius)) failures.Add($"{export.ObjectName}: non-finite radius");
            }
            catch (Exception ex)
            {
                failures.Add($"{export.ObjectName}: {ex.Message}");
            }
        }

        Assert.Empty(failures);
    }

    [RequiresGameFact]
    public void SocketReader_ReturnsNothingRatherThanGarbage()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        // Meshes without a socket table must yield an empty list, never "None" entries — the guard
        // exists because the layout around the table is not yet fully understood.
        foreach (var export in package.Exports.Where(e => package.GetClassName(e) == "SkeletalMesh"))
        {
            if (export.SerialSize < 128) continue;
            var sockets = SkeletalMeshReader.ReadSockets(package.ReadExportData(export), package.Names);
            Assert.All(sockets, s =>
            {
                Assert.NotEqual("None", s.Name);
                Assert.NotEqual("None", s.BoneName);
                Assert.NotEmpty(s.Name);
            });
        }
    }
}
