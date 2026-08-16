using BioShockStudio.Core.Havok.Detection;
using BioShockStudio.Core.Havok.Packfile;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class HavokPackfileTests(GameFixture game)
{
    /// <summary>
    /// Object names are not unique within a package — a SkeletalMesh and the Package object that
    /// holds it can share a name — so the class must be part of the lookup.
    /// </summary>
    private static byte[] LoadExport(string packageFile, string className, string objectName)
    {
        using var package = BioShockPackage.Open(packageFile);
        var export = package.Exports.First(e =>
            e.ObjectName == objectName && package.GetClassName(e) == className);
        return package.ReadExportData(export);
    }

    private byte[] HandsAnimationPackage() =>
        LoadExport(game.LighthousePackage, "AnimationPackageWrapper", "UAPW_NEWPlayerHands");

    [RequiresGameFact]
    public void FirstPersonHandsAnimationPackage_ContainsHavokPackfiles()
    {
        byte[] payload = HandsAnimationPackage();
        var hits = HavokDetector.FindAll(payload).ToList();

        Assert.NotEmpty(hits);
    }

    [RequiresGameFact]
    public void EmbeddedPackfiles_MatchConfirmedHavokLayout()
    {
        byte[] payload = HandsAnimationPackage();

        foreach (var hit in HavokDetector.FindAll(payload))
        {
            var header = hit.Header;

            // CONFIRMED_BYTES for BioShock 1 Remastered.
            Assert.Equal("hk_2012.2.0-r1", header.ContentsVersion);
            Assert.Equal(9, header.FileVersion);
            Assert.Equal(4, header.BytesInPointer);
            Assert.True(header.IsLittleEndian);

            // Section count is content-dependent, so the invariant is the arithmetic, not a constant:
            // a 64-byte header followed by one 48-byte header per section.
            Assert.Equal(64 + header.NumSections * 48, header.AbsoluteDataStart);

            // The contents section is the last one, which is the __data__ section.
            Assert.Equal(header.NumSections - 1, header.ContentsSectionIndex);
        }
    }

    [RequiresGameFact]
    public void EmbeddedPackfiles_BeginAndEndWithTheStandardSections()
    {
        byte[] payload = HandsAnimationPackage();
        var hit = HavokDetector.FindFirst(payload);
        Assert.NotNull(hit);

        var packfile = HavokPackfile.Parse(payload, hit!.Value.Offset);

        Assert.Equal("__classnames__", packfile.Sections[0].SectionTag);
        Assert.Equal("__types__", packfile.Sections[1].SectionTag);
        Assert.Equal("__data__", packfile.Sections[^1].SectionTag);

        // The first section's data begins exactly where the header table ends.
        Assert.Equal(packfile.Header.AbsoluteDataStart, packfile.Sections[0].AbsoluteDataStart);
    }

    [RequiresGameFact]
    public void HandsAnimationPackage_PartitionsAnimationsPerWeapon()
    {
        byte[] payload = HandsAnimationPackage();
        var packfile = HavokPackfile.Parse(payload, HavokDetector.FindFirst(payload)!.Value.Offset);
        var tags = packfile.Sections.Select(s => s.SectionTag).ToList();

        // Between the standard head and tail sections, 2K inserts one section per weapon. This is
        // the mechanism that ties first-person hand animations to a specific weapon.
        Assert.Contains("pistol", tags);
        Assert.Contains("shotgun", tags);
        Assert.Contains("tommygun", tags);
        Assert.Contains("wrench", tags);
        Assert.Contains("crossbow", tags);
        Assert.Contains("default", tags);

        // Tags are capped at 19 bytes; names that would collide when truncated carry a numeric
        // suffix in the shipped bytes (HYPOTHESIS: a hash of the untruncated name).
        Assert.Contains(tags, t => t.StartsWith("chemical", StringComparison.Ordinal));
        Assert.Contains(tags, t => t.StartsWith("grenadel", StringComparison.Ordinal));

        var pistol = packfile.FindSection("pistol");
        Assert.NotNull(pistol);
        Assert.True(pistol!.DataSize > 0);
        Assert.True(pistol.LocalFixupsSize > 0);
    }

    [RequiresGameFact]
    public void ThirdPersonAnimationPackage_HasNoPerWeaponSections()
    {
        byte[] payload = LoadExport(game.LighthousePackage, "AnimationPackageWrapper", "UAPW_AggressorBabyJane");
        var packfile = HavokPackfile.Parse(payload, HavokDetector.FindFirst(payload)!.Value.Offset);

        // A third-person character ships the stock head/tail sections plus a single "default"
        // section. Per-weapon partitioning is therefore a structural first-person signal, not a
        // naming convention.
        Assert.Equal(
            new[] { "__classnames__", "__types__", "default", "__data__" },
            packfile.Sections.Select(s => s.SectionTag));

        var classes = packfile.ClassNames.Values.ToHashSet(StringComparer.Ordinal);

        // Third-person characters carry ragdoll and physics classes; the first-person hands do not.
        Assert.Contains("hkaRagdollInstance", classes);
        Assert.Contains("hkpRigidBody", classes);
        Assert.Contains("hkaSkeletonMapper", classes);
    }

    [RequiresGameFact]
    public void AnimationPackageWrappers_PrefixTheHavokPackfileConsistently()
    {
        // The Unreal wrapper is a fixed-size prefix ahead of the Havok magic. Its contents are still
        // unknown, so nothing hardcodes the offset — but the value is recorded here so a future
        // sample that differs fails loudly instead of passing silently.
        foreach (string name in new[] { "UAPW_NEWPlayerHands", "UAPW_AggressorBabyJane", "UAPW_HandInsectAnim" })
        {
            byte[] payload = LoadExport(game.LighthousePackage, "AnimationPackageWrapper", name);
            var hit = HavokDetector.FindFirst(payload);

            Assert.NotNull(hit);
            Assert.Equal(34, hit!.Value.Offset);
            Assert.Equal("AnimationPackageRoot", HavokPackfile.Parse(payload, hit.Value.Offset).ContentsClassName);
        }
    }

    [RequiresGameFact]
    public void HandsAnimationPackage_RootIsAnimationPackageRoot()
    {
        byte[] payload = HandsAnimationPackage();
        var packfile = HavokPackfile.Parse(payload, HavokDetector.FindFirst(payload)!.Value.Offset);

        // This is the 2K-specific root class that stock Havok tooling and UEViewer do not know.
        Assert.Equal("AnimationPackageRoot", packfile.ContentsClassName);

        var classes = packfile.ClassNames.Values.ToHashSet(StringComparer.Ordinal);
        Assert.Contains("hkaSkeleton", classes);
        Assert.Contains("hkaAnimationBinding", classes);
        Assert.Contains("hkaSplineCompressedAnimation", classes);
    }

    [RequiresGameFact]
    public void EmbeddedPackfiles_SectionRegionsAreOrdered()
    {
        byte[] payload = HandsAnimationPackage();

        foreach (var hit in HavokDetector.FindAll(payload))
        {
            var packfile = HavokPackfile.Parse(payload, hit.Offset);
            foreach (var s in packfile.Sections)
            {
                // Each region's start must not exceed the next one's; sizes are the differences.
                Assert.True(s.LocalFixupsOffset <= s.GlobalFixupsOffset);
                Assert.True(s.GlobalFixupsOffset <= s.VirtualFixupsOffset);
                Assert.True(s.VirtualFixupsOffset <= s.ExportsOffset);
                Assert.True(s.ExportsOffset <= s.ImportsOffset);
                Assert.True(s.ImportsOffset <= s.EndOffset);
            }
        }
    }

    [RequiresGameFact]
    public void ClassNameTable_DecodesHavokAnimationClasses()
    {
        byte[] payload = HandsAnimationPackage();
        var hit = HavokDetector.FindFirst(payload);
        Assert.NotNull(hit);

        var packfile = HavokPackfile.Parse(payload, hit!.Value.Offset);
        var classes = packfile.ClassNames.Values.ToHashSet(StringComparer.Ordinal);

        Assert.NotEmpty(classes);
        // Every class name is a plausible Havok identifier, not garbage from a misaligned reader.
        Assert.All(classes, c => Assert.Matches("^[A-Za-z_][A-Za-z0-9_:]*$", c));
    }
}
