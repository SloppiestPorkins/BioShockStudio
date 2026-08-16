using System.Numerics;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// A socket carries its own offset and rotation from the bone it hangs off.
/// </summary>
/// <remarks>
/// <para>
/// <c>CONFIRMED_EXTERNAL</c> from UModel — <c>USkeletalMesh</c> serialises
/// <c>AttachAliases</c>, <c>AttachBoneNames</c> and <c>AttachCoords</c>, the last an
/// <c>FCoords</c> of origin plus three axes — then <c>CONFIRMED_BYTES</c> here.
/// </para>
/// <para>
/// This was missed for a long time for an instructive reason: <b>every first-person weapon socket
/// has a zero origin</b>, so the pistol, wrench and Tommy gun all placed correctly on the bone alone
/// and the notes concluded sockets had no offset. 60% of the game's sockets do.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class SocketTransformTests(GameFixture game)
{
    private IReadOnlyList<MeshSocket> Sockets(string map, string mesh)
    {
        using var package = BioShockPackage.Open(
            Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), map + ".bsm"));

        var export = package.Exports
            .Where(e => package.GetClassName(e) == "SkeletalMesh"
                        && string.Equals(e.ObjectName, mesh, StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);

        Assert.True(export is not null, $"{mesh} is not in {map}");
        return SkeletalMeshReader.ReadSockets(package.ReadExportData(export!), package.Names);
    }

    /// <summary>Every socket frame decodes to an exact rotation — the check that this is the array.</summary>
    [RequiresGameFact]
    public void EverySocketFrameIsOrthonormal()
    {
        int checkedSockets = 0;

        foreach (var (map, mesh) in new[]
                 {
                     ("0-Lighthouse", "NEWPlayerHands"),
                     ("7-Gauntlet", "ProtectorRosie"),
                     ("4-Recreation", "SecurityBot"),
                 })
        {
            foreach (var socket in Sockets(map, mesh))
            {
                var m = socket.Transform;

                var x = new Vector3(m.M11, m.M12, m.M13);
                var y = new Vector3(m.M21, m.M22, m.M23);
                var z = new Vector3(m.M31, m.M32, m.M33);

                Assert.Equal(1f, x.Length(), 2);
                Assert.Equal(1f, y.Length(), 2);
                Assert.Equal(1f, z.Length(), 2);
                Assert.Equal(0f, Vector3.Dot(x, y), 2);
                Assert.Equal(0f, Vector3.Dot(x, z), 2);
                Assert.Equal(0f, Vector3.Dot(y, z), 2);

                checkedSockets++;
            }
        }

        Assert.True(checkedSockets >= 30, $"only {checkedSockets} sockets checked");
    }

    /// <summary>
    /// The first-person weapon sockets sit exactly on their bone — which is why ignoring the offset
    /// looked correct for years — while others do not.
    /// </summary>
    [RequiresGameFact]
    public void WeaponSocketsSitOnTheBoneAndOthersDoNot()
    {
        var hands = Sockets("0-Lighthouse", "NEWPlayerHands")
            .ToDictionary(s => s.Name, StringComparer.OrdinalIgnoreCase);

        // Every weapon the player holds: no offset, so the pistol always looked right.
        foreach (string weapon in new[] { "Pistol", "Wrench", "TommyGun", "Crossbow", "Launcher", "Chem" })
        {
            Assert.True(hands.ContainsKey(weapon), $"no {weapon} socket");
            Assert.True(hands[weapon].Transform.Translation.Length() < 0.01f,
                $"{weapon} has an offset of {hands[weapon].Transform.Translation.Length():0.##}");
        }

        // And these do — the reason props were misplaced.
        Assert.True(hands["FireballSocket"].Transform.Translation.Length() > 60f);
        Assert.True(hands["GathererAttach"].Transform.Translation.Length() > 80f);
        Assert.True(hands["WrenchRibbonSocket"].Transform.Translation.Length() > 30f);
    }

    /// <summary>
    /// Game-wide: the offsets are common, so this is not a rarity that could be ignored.
    /// </summary>
    [RequiresGameFact]
    public void MostSocketsCarryATransformTheBoneAloneWouldMiss()
    {
        int sockets = 0, offset = 0, rotated = 0;
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (string map in Directory.GetFiles(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "*.bsm"))
        {
            using var package = BioShockPackage.Open(map);

            foreach (var export in package.Exports.Where(e =>
                         package.GetClassName(e) == "SkeletalMesh" && e.SerialSize > 0))
            {
                if (!seen.Add(export.ObjectName)) continue;

                foreach (var socket in SkeletalMeshReader.ReadSockets(
                             package.ReadExportData(export), package.Names))
                {
                    sockets++;
                    if (socket.Transform.Translation.Length() > 0.01f) offset++;

                    var rotation = socket.Transform;
                    rotation.Translation = Vector3.Zero;
                    if (!rotation.IsIdentity) rotated++;
                }
            }
        }

        Assert.True(sockets > 300, $"only {sockets} sockets swept");

        // Measured: 200 of 332 offset, 246 rotated. A regression to bone-only placement makes both
        // of these zero, which is what this test exists to catch.
        Assert.True(offset > sockets / 3, $"only {offset} of {sockets} sockets carry an offset");
        Assert.True(rotated > sockets / 2, $"only {rotated} of {sockets} sockets carry a rotation");
    }
}
