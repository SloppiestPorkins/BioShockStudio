using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Covers the application services the GUI is built on.
/// <para>
/// These are the layer between the window and the extraction libraries, so they are tested without
/// a window — which is the point of having them. They still read the real install.
/// </para>
/// </summary>
[Collection(GameCollection.Name)]
public sealed class ServiceTests(GameFixture game)
{
    private AssetCatalogService Catalog()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        return catalog;
    }

    private static IReadOnlyList<CatalogEntry> Lighthouse(GameFixture game)
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        return AssetCatalogService.Catalogue(package, "0-Lighthouse");
    }

    // ------------------------------------------------------------------ installation

    [RequiresGameFact]
    public void Installation_AcceptsTheRealInstallAndListsItsPackages()
    {
        var report = new InstallationService().Validate(game.RequireRoot);

        Assert.True(report.IsUsable, report.Problem);
        Assert.Null(report.Problem);
        Assert.All(report.Checks.Where(c => c.Required), c => Assert.True(c.Passed, c.Name));
        Assert.Contains("0-Lighthouse", report.Packages);
    }

    [Fact]
    public void Installation_ExplainsWhatIsWrongInsteadOfThrowing()
    {
        var service = new InstallationService();

        var missing = service.Validate(Path.Combine(Path.GetTempPath(), $"not-a-game-{Guid.NewGuid():N}"));
        Assert.False(missing.IsUsable);
        Assert.NotNull(missing.Problem);

        // An existing folder that is not the game must be rejected with an explanation of what the
        // user should pick instead, not with a parse error from somewhere deep in the reader.
        var wrong = service.Validate(Path.GetTempPath());
        Assert.False(wrong.IsUsable);
        Assert.Contains("BioShock Remastered", wrong.Problem!, StringComparison.OrdinalIgnoreCase);

        var nothing = service.Validate(null);
        Assert.False(nothing.IsUsable);
    }

    // ------------------------------------------------------------------ settings

    [Fact]
    public void Settings_RoundTripAndSurviveACorruptFile()
    {
        string path = Path.Combine(Path.GetTempPath(), $"bioshock-settings-{Guid.NewGuid():N}.json");
        var service = new SettingsService(path);

        try
        {
            // Nothing saved yet: defaults, not a crash.
            Assert.True(service.Load().ExportFbx);

            Assert.True(service.Save(new AppSettings
            {
                GamePath = @"C:\Games\BioShock",
                OutputDirectory = @"D:\Out",
                ExportDds = true,
                ExportFbx = false,
                ResearchMode = true,
            }));

            var loaded = service.Load();
            Assert.Equal(@"C:\Games\BioShock", loaded.GamePath);
            Assert.Equal(@"D:\Out", loaded.OutputDirectory);
            Assert.True(loaded.ExportDds);
            Assert.False(loaded.ExportFbx);
            Assert.True(loaded.ResearchMode);

            // A corrupt settings file must never be the reason the application will not open.
            File.WriteAllText(path, "{ this is not json");
            Assert.True(service.Load().ExportFbx);
        }
        finally
        {
            if (File.Exists(path)) File.Delete(path);
        }
    }

    // ------------------------------------------------------------------ catalogue

    [RequiresGameFact]
    public void Catalogue_PutsTheHandsWeaponsAndCharactersInTheRightPlaces()
    {
        var entries = Lighthouse(game);

        var hands = entries.Single(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);
        Assert.Equal("0-Lighthouse", hands.Package);
        Assert.Equal("UAPW_NEWPlayerHands", hands.ObjectName);

        // A structural classification, not a name match: a group owning both a skeletal mesh and an
        // animation package, with enough substance to be a character rather than a door.
        Assert.Contains(entries, e => e.Category == AssetCategory.Characters);
        Assert.Contains(entries, e => e.Category == AssetCategory.Textures && e.Name == "Hand_DIFF");
        Assert.Contains(entries, e => e.Category == AssetCategory.Materials);
        Assert.Contains(entries, e => e.Category == AssetCategory.SkeletalMeshes && e.Name == "NEWPlayerHands");
    }

    [RequiresGameFact]
    public void Catalogue_NamesAnimationsAsTheUserWouldRatherThanAsTheMetadataObject()
    {
        var entries = Lighthouse(game);

        var reload = entries.FirstOrDefault(e =>
            e.Category == AssetCategory.Animations && e.Name == "FastReloadPistol");

        Assert.NotNull(reload);
        Assert.StartsWith("USharedSkeletonAnimationMetadata_", reload.ObjectName, StringComparison.Ordinal);
        Assert.Equal("NEWPlayerHands", reload.OwnerGroup);
    }

    [RequiresGameFact]
    public void Catalogue_LeavesUnclassifiableExportsOutRatherThanInventingACategory()
    {
        var entries = Lighthouse(game);

        // Notifies, package objects and script classes have no user-facing meaning, so they are not
        // shown. Nothing may be filed under Other with a confident-looking name.
        Assert.DoesNotContain(entries, e => e.Category == AssetCategory.Other);
        Assert.All(entries, e => Assert.False(string.IsNullOrWhiteSpace(e.Name)));
    }

    [RequiresGameFact]
    public async Task Catalogue_CollapsesTheSameAssetAcrossPackages()
    {
        var catalog = new AssetCatalogService();
        await catalog.BuildAsync(game.RequireRoot);

        // Every map embeds its own copy of what it uses. The hands are in all twenty, and browsing
        // twenty identical rows is not useful.
        var hands = catalog.Search("NEWPlayerHands", AssetCategory.FirstPerson);
        var row = Assert.Single(hands);
        Assert.True(row.PackageCount > 1, "the hands appear in more than one package");
        Assert.Contains("0-Lighthouse", row.Packages);
        Assert.Contains($"in {row.PackageCount} packages", row.Detail);

        // Nothing may appear twice under the same identity.
        var duplicates = catalog.Entries
            .GroupBy(e => $"{e.Category}|{e.ClassName}|{e.Group}|{e.Name}", StringComparer.OrdinalIgnoreCase)
            .Where(g => g.Count() > 1)
            .ToList();
        Assert.Empty(duplicates);

        // A collapsed row still belongs to every package that carries it, so filtering by map must
        // not hide an asset that map genuinely contains.
        var inChallenge = catalog.Search("NEWPlayerHands", AssetCategory.FirstPerson, "ChallengeRoomCombat");
        Assert.Single(inChallenge);
    }

    [RequiresGameFact]
    public async Task Catalogue_DescribesTexturesAndMaterialsByWhatTheyAre()
    {
        var catalog = new AssetCatalogService();
        await catalog.BuildAsync(game.RequireRoot);

        // A byte count tells nobody whether a texture is the one they want.
        var texture = catalog.Search("Hand_DIFF", AssetCategory.Textures).First();
        Assert.Matches(@"\d+ × \d+ · \w+", texture.Detail);

        var material = catalog.Search("NEWplayerHandsRimShader", AssetCategory.Materials).First();
        Assert.Contains("FacingShader", material.Detail);
        Assert.Contains("textures", material.Detail);
    }

    [RequiresGameFact]
    public async Task Catalogue_SearchesAcrossNamePackageAndGroup()
    {
        var catalog = new AssetCatalogService();
        await catalog.BuildAsync(game.RequireRoot);

        Assert.True(catalog.IsLoaded);
        Assert.Empty(catalog.Failures);

        // Each of these is a different field: object name, group, and a texture whose group is the
        // asset the user is actually looking for.
        Assert.Contains(catalog.Search("NEWPlayerHands"), e => e.Category == AssetCategory.FirstPerson);
        Assert.Contains(catalog.Search("Hand_DIFF"), e => e.Category == AssetCategory.Textures);
        Assert.NotEmpty(catalog.Search("Pistol"));

        var textures = catalog.Search("Hand_", AssetCategory.Textures);
        Assert.All(textures, e => Assert.Equal(AssetCategory.Textures, e.Category));

        var limited = catalog.Search(null, limit: 10);
        Assert.Equal(10, limited.Count);
    }

    // ------------------------------------------------------------------ details

    [RequiresGameFact]
    public void Details_ForTheHandsReportTheSkeletonAnimationsSocketsAndMaterial()
    {
        var catalog = Catalog();
        var entry = Lighthouse(game).Single(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);

        var details = new AssetDetailsService(catalog).Describe(entry);

        Assert.Null(details.Problem);
        Assert.Contains(details.Fields, f => f.Label == "Skeleton" && f.Value.Contains("47 bones"));
        Assert.Contains(details.Sections, s => s.Title == "Animations" && s.Items.Count == 130);
        Assert.Contains(details.Sections, s => s.Title == "Sockets" && s.Items.Any(i => i.Name == "Pistol"));

        // The hands' shader is a FacingShader, so its slots must be reported as they are.
        var material = details.Sections.Single(s => s.Title.StartsWith("Material", StringComparison.Ordinal));
        Assert.Contains(material.Items, i => i.Name == "Hand_DIFF");
        Assert.Contains(material.Items, i => i.Detail.Contains("FacingDiffuse", StringComparison.Ordinal));
    }

    [RequiresGameFact]
    public void Details_SayWhenAMeshCannotBeReadRatherThanShowingNothing()
    {
        var catalog = Catalog();
        using var package = BioShockPackage.Open(
            Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));
        var entries = AssetCatalogService.Catalogue(package, "1-Medical");

        // The doors are the last unreadable skeletal variant; the weapon viewmodels all read now.
        var broken = entries.FirstOrDefault(e =>
            e.Category == AssetCategory.SkeletalMeshes && e.Name == "LowRentDoor_Mesh");
        Assert.NotNull(broken);

        var details = new AssetDetailsService(catalog).Describe(broken);

        // This mesh is a known unsupported variant. The panel must say so in the user's terms.
        Assert.NotNull(details.Problem);
        Assert.Contains("does not read yet", details.Problem, StringComparison.OrdinalIgnoreCase);
    }

    [RequiresGameFact]
    public void Details_RelationshipsCarryTheirConfidence()
    {
        var catalog = Catalog();
        var entry = Lighthouse(game).Single(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);

        var details = new AssetDetailsService(catalog).Describe(entry);

        // Nothing may be presented without saying how it was established.
        foreach (var section in details.Sections)
            Assert.All(section.Items, item => Assert.False(string.IsNullOrWhiteSpace(item.Confidence)));
    }

    // ------------------------------------------------------------------ texture preview

    [RequiresGameFact]
    public void TexturePreview_DecodesARealTextureAtAReasonableSize()
    {
        var catalog = Catalog();
        var entry = Lighthouse(game).First(e => e.Category == AssetCategory.Textures && e.Name == "Hand_DIFF");
        var service = new TexturePreviewService(catalog);

        var described = service.Describe(entry);
        Assert.NotNull(described);
        Assert.True(described.Width > 0 && described.Height > 0);
        Assert.NotEmpty(described.Mips);

        var image = service.Decode(entry);
        Assert.NotNull(image);
        Assert.Equal(image.Width * image.Height * 4, image.Rgba.Length);

        // Browsing must not allocate a 2048-square image per selection.
        Assert.True(Math.Max(image.Width, image.Height) <= TexturePreviewService.PreferredMaximumSize);

        // The full-resolution mip is still reachable for anyone who asks for it.
        var full = service.Decode(entry, 0);
        Assert.NotNull(full);
        Assert.Equal(described.Width, full.Width);
    }

    // ------------------------------------------------------------------ extraction

    [RequiresGameFact]
    public async Task Extraction_WritesTexturesAndReportsProgress()
    {
        var catalog = Catalog();
        var entries = Lighthouse(game)
            .Where(e => e.Category == AssetCategory.Textures && e.Group == "NEWPlayerHands")
            .Take(3)
            .ToList();
        Assert.NotEmpty(entries);

        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-extract-{Guid.NewGuid():N}");
        var reports = new List<ExtractionProgress>();

        try
        {
            var report = await new ExtractionService(catalog).RunAsync(
                entries,
                new ExtractionOptions { OutputDirectory = directory, Formats = ExportFormats.Png },
                new Progress<ExtractionProgress>(reports.Add));

            Assert.False(report.Cancelled);
            Assert.Equal(entries.Count, report.Succeeded);
            Assert.Empty(report.Failures);
            Assert.NotEmpty(Directory.GetFiles(directory, "*.png", SearchOption.AllDirectories));
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    [RequiresGameFact]
    public async Task Extraction_RecordsAFailureAndKeepsGoing()
    {
        var catalog = Catalog();

        // A group with no animation package cannot be exported as a scene; the job must still finish
        // the assets either side of it.
        var good = Lighthouse(game).First(e => e.Category == AssetCategory.Textures);
        var bad = good with
        {
            Category = AssetCategory.Characters,
            Name = "not-a-real-group",
            Group = "not-a-real-group",
        };

        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-extract-{Guid.NewGuid():N}");

        try
        {
            var report = await new ExtractionService(catalog).RunAsync(
                [bad, good],
                new ExtractionOptions
                {
                    OutputDirectory = directory,
                    Formats = ExportFormats.Png | ExportFormats.SceneJson,
                });

            Assert.Equal(1, report.Failed);
            Assert.Equal(1, report.Succeeded);
            Assert.Contains(report.Failures, f => f.Message is not null && f.Message.Length > 0);
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    [RequiresGameFact]
    public async Task Extraction_OfTheHandsWritesASceneWithItsTextures()
    {
        var catalog = Catalog();
        var entry = Lighthouse(game).Single(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);
        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-extract-{Guid.NewGuid():N}");

        try
        {
            var report = await new ExtractionService(catalog).RunAsync(
                [entry],
                new ExtractionOptions { OutputDirectory = directory, Formats = ExportFormats.SceneJson });

            Assert.Equal(1, report.Succeeded);
            Assert.NotEmpty(Directory.GetFiles(directory, "*.json", SearchOption.AllDirectories));

            // The material's textures travel with the scene, so the export is not untextured.
            Assert.NotEmpty(Directory.GetFiles(directory, "Hand_*.png", SearchOption.AllDirectories));
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    [RequiresGameFact]
    public async Task Extraction_StopsWhenCancelled()
    {
        var catalog = Catalog();
        var entries = Lighthouse(game).Where(e => e.Category == AssetCategory.Textures).Take(50).ToList();

        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-extract-{Guid.NewGuid():N}");
        using var cancellation = new CancellationTokenSource();

        try
        {
            var progress = new Progress<ExtractionProgress>(p =>
            {
                if (p.Completed >= 2) cancellation.Cancel();
            });

            var report = await new ExtractionService(catalog).RunAsync(
                entries,
                new ExtractionOptions { OutputDirectory = directory, Formats = ExportFormats.Png },
                progress,
                cancellation.Token);

            // Cancelling must leave what was already written and simply stop, not throw at the caller.
            Assert.True(report.Cancelled);
            Assert.True(report.Results.Count < entries.Count);
        }
        catch (OperationCanceledException)
        {
            // Also acceptable: the job was cancelled before it reported anything.
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }
}
