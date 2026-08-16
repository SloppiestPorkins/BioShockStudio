using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The window searches the catalogue while the catalogue is still being built, so both have to
/// tolerate it.
/// </summary>
/// <remarks>
/// This crashed the shipped application: typing in the search box during a build threw
/// <c>System.InvalidOperationException: Collection was modified; enumeration operation may not
/// execute</c> out of <c>AssetCatalogService.Search</c>, because <c>BuildAsync</c> cleared and
/// refilled the same list the UI thread was walking. Nothing in the suite exercised the two
/// together, so every single-threaded test passed throughout.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class CatalogConcurrencyTests(GameFixture game)
{
    [RequiresGameFact]
    public async Task SearchingWhileTheCatalogueIsBuildingDoesNotThrow()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var stop = new CancellationTokenSource();
        Exception? failure = null;
        long searches = 0;

        // Hammer the read side the way the search box does — every keystroke re-filters.
        var readers = Enumerable.Range(0, 4).Select(_ => Task.Run(() =>
        {
            string[] terms = ["a", "at", "atl", "hand", "pistol", "", "Bip01", "shader"];
            int i = 0;
            while (!stop.IsCancellationRequested)
            {
                try
                {
                    catalog.Search(terms[i++ % terms.Length]);
                    catalog.CategoryCounts();
                    _ = catalog.Entries.Count;
                    Interlocked.Increment(ref searches);
                }
                catch (Exception ex)
                {
                    Interlocked.CompareExchange(ref failure, ex, null);
                    return;
                }
            }
        })).ToArray();

        try
        {
            await catalog.BuildAsync(game.RequireRoot);
        }
        finally
        {
            stop.Cancel();
            await Task.WhenAll(readers);
        }

        Assert.Null(failure);

        // The test is only meaningful if the readers actually ran against a moving catalogue.
        Assert.True(Interlocked.Read(ref searches) > 100, $"only {searches} searches ran");
        Assert.True(catalog.IsLoaded, "the build produced no entries");
    }
}
