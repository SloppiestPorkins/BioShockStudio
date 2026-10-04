using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// An array of structs declares a size that omits the explicit size byte of each nested Object
/// property — the array counterpart of <see cref="StructSizeTests"/>.
/// </summary>
/// <remarks>
/// Found through Medical's Fisheries quarantine gate: <c>BooleanStatement61</c>'s
/// <c>resolveInfoList</c> (lhs ← <c>ActionGetNumItemsInPlayersInventory89</c>) declares 40 bytes for
/// 41, so the struct-array decode failed, the getter link was dropped from the script export, and the
/// gate's "holds Steinman's key" test could never come out true. A census of all 21 packages found
/// 8,296 such arrays (Materials, resolveInfoList, MaterialSlot, SequenceItems, PatrolEntries) and no
/// array with Object size bytes that declared them.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class ArraySizeTests(GameFixture game)
{
    private static List<UnrealProperty> Properties(BioShockPackage package, string objectName)
    {
        var export = package.Exports.Single(e => e.ObjectName == objectName);
        var list = UnrealPropertyReader.Read(package.ReadExportData(export), package.Names, out _, out bool truncated);
        Assert.False(truncated, $"{objectName}'s property list must end on a clean terminator");
        return list;
    }

    /// <summary>One array on each side of the rule, both from 1-Medical.</summary>
    [RequiresGameFact]
    public void BothSidesOfTheArraySizeRuleDecodeCompletely()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);

        // Short side: the Action field carries an explicit size byte (55 03 7AC603), uncounted.
        var statement = Properties(package, "BooleanStatement61");
        var resolve = statement.Single(p => p.Name == "resolveInfoList");
        Assert.True(PropertyValues.TryAsStructArrayExact(resolve, package, out var elements),
            "BooleanStatement61.resolveInfoList declares 40 bytes for 41 and used to fail to decode");
        var element = Assert.Single(elements);
        var propertyName = element.Single(f => f.Name == "PropertyName");
        Assert.Equal("lhs", PropertyValues.AsName(propertyName, package));
        Assert.True(element.Single(f => f.Name == "Action").TryAsObjectReference(out var action));
        Assert.True(action.IsExport);
        Assert.Equal("ActionGetNumItemsInPlayersInventory89", package.Exports[action.ExportIndex].ObjectName);
        // The walk now carries on to the property that used to be left as trailing bytes.
        Assert.Contains(statement, p => p.Name == "CheckpointTypePadding");

        // Exact side: a null Action (encoding 0, no size byte) declares its size correctly.
        var filter = Properties(package, "ActionFilterItem6");
        Assert.True(PropertyValues.TryAsStructArrayExact(
            filter.Single(p => p.Name == "resolveInfoList"), package, out var filterElements));
        Assert.Equal("UnFilter", PropertyValues.AsName(
            Assert.Single(filterElements).Single(f => f.Name == "PropertyName"), package));
    }
}
