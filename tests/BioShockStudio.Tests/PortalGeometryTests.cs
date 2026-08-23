using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Portal geometry: which zones each portal polygon joins.
/// </summary>
/// <remarks>
/// <para>
/// Gate 3 item 1 listed "actual portal geometry (as opposed to zone-to-zone adjacency)" as open.
/// It was reachable from two bytes nothing was reading, and <b>the reference had both of them
/// wrong</b>: Nyko's SDK notes label <c>+76</c> as <c>NodeFlags</c> and <c>+79</c> as
/// "iZone[1] / Pad". The shipped bytes say the opposite - <c>+76</c> is a zone index and
/// <c>+79</c> is the flag byte.
/// </para>
/// <para>
/// <b>The evidence is the cross-check, not the plausibility.</b> Each portal polygon names two
/// zones, and every one of those pairs is already claimed by both zones' 128-bit connectivity
/// masks - which were decoded from the zone records, a different part of the file entirely. Two
/// independent structures agreeing is what makes this a decode rather than a guess.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class PortalGeometryTests(GameFixture game)
{
    [RequiresGameFact]
    public void PortalZonePairsAgreeWithTheZoneConnectivityMasks()
    {
        long portals = 0, joiningTwoZones = 0, agrees = 0;
        var disagreements = new List<string>();
        var nodeFlagValues = new Dictionary<byte, long>();
        long polygons = 0, portalsWithoutFlag = 0, nonPortalsWithFlag = 0;
        var frontZoneValues = new HashSet<byte>();

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(map);
            var built = ModelReader.BuiltWorld(package);
            if (built is null) continue;

            BspWorld? world;
            try { world = BspWorldReader.Read(package, package.Exports[built.Source.ExportIndex]); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }
            if (world is null || world.PolygonCount == 0) continue;

            foreach (var node in world.Nodes)
            {
                if (!node.IsPolygon) continue;
                polygons++;

                nodeFlagValues[node.NodeFlags] = nodeFlagValues.GetValueOrDefault(node.NodeFlags) + 1;
                frontZoneValues.Add(node.FrontZone);

                bool portalSurface = node.Surface >= 0 && node.Surface < world.Surfaces.Count
                                     && (world.Surfaces[node.Surface].Flags & BspSurfaceFlags.Portal) != 0;

                if (portalSurface && !node.IsPortalNode) portalsWithoutFlag++;
                if (!portalSurface && node.IsPortalNode) nonPortalsWithFlag++;
                if (!portalSurface) continue;

                portals++;
                if (node.FrontZone == node.Zone) continue;

                joiningTwoZones++;
                if (node.FrontZone >= world.Zones.Count || node.Zone >= world.Zones.Count) continue;

                bool forward = world.Zones[node.FrontZone].ConnectedZones.Contains(node.Zone);
                bool backward = world.Zones[node.Zone].ConnectedZones.Contains(node.FrontZone);

                if (forward && backward) agrees++;
                else if (disagreements.Count < 8)
                    disagreements.Add($"{Path.GetFileNameWithoutExtension(map)} "
                        + $"({node.FrontZone},{node.Zone}) fwd={forward} back={backward}");
            }
        }

        Assert.True(portals > 2_000, $"only {portals} portal surfaces found");

        // THE CHECK: every portal pair is corroborated by the independently-decoded zone masks.
        Assert.Equal(joiningTwoZones, agrees);
        Assert.Empty(disagreements);

        // +76 behaves like a zone index, not a flag: a wide range of values.
        Assert.True(frontZoneValues.Count > 50,
            $"+76 takes only {frontZoneValues.Count} distinct values, which is not an index");

        // +79 behaves like a flag byte, not an index: a handful of values.
        Assert.True(nodeFlagValues.Count <= 8,
            $"+79 takes {nodeFlagValues.Count} distinct values, which is not a flag byte");

        // ...and the flag identifies portals exactly.
        Assert.Equal(0, portalsWithoutFlag);
        Assert.True(nonPortalsWithFlag < polygons / 1000,
            $"{nonPortalsWithFlag} non-portal nodes carry the portal flags value");
    }
}
