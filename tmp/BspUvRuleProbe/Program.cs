using BioShockStudio.Core.Export;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;

var remaster = @"G:\SteamLibrary\steamapps\common\BioShock Remastered\ContentBaked\pc\Maps\1-Medical.bsm";
Environment.SetEnvironmentVariable("BIOSHOCK_ORIGINAL_TEXTURE_DIR",
    @"G:\SteamLibrary\steamapps\common\Bioshock\Builds\Release\UmodelExport\1-Medical\Texture");

using var package = BioShockPackage.Open(remaster);
var model = ModelReader.BuiltWorld(package)!;
var world = BspWorldReader.Read(package, package.Exports[model.Source.ExportIndex])!;

string[] mats =
[
    "Bathroom_Tile_BW_Diffuse_shader",
    "Medical_ceilling_Diffuse_shader",
    "med_wall_public_shader",
];

foreach (string matName in mats)
{
    int exportIdx = -1;
    for (int i = 0; i < package.Exports.Count; i++)
    {
        if (package.Exports[i].ObjectName == matName) { exportIdx = i; break; }
    }
    if (exportIdx < 0) { Console.WriteLine($"MISSING {matName}"); continue; }
    int matRef = exportIdx + 1;

    var uMags = new List<float>();
    var vMags = new List<float>();
    int surfaces = 0;
    foreach (var s in world.Surfaces)
    {
        if (s.Material.Value != matRef || !s.IsDrawn) continue;
        surfaces++;
        if (s.TextureU >= 0 && s.TextureU < world.Vectors.Count)
            uMags.Add(world.Vectors[s.TextureU].Length());
        if (s.TextureV >= 0 && s.TextureV < world.Vectors.Count)
            vMags.Add(world.Vectors[s.TextureV].Length());
    }
    uMags.Sort();
    vMags.Sort();
    float um = uMags.Count > 0 ? uMags[uMags.Count / 2] : 0;
    float vm = vMags.Count > 0 ? vMags[vMags.Count / 2] : 0;
    var distinctU = uMags.Select(x => MathF.Round(x, 3)).Distinct().OrderBy(x => x).ToList();

    var exp = package.Exports[exportIdx];
    var authored = LevelSceneExporter.AuthoredTextureSize(
        package, new SourceId(package.FilePath, exportIdx, package.GetClassName(exp), exp.ObjectName));
    BioShockMaterial? decoded = null;
    try { decoded = MaterialReader.Read(package, package.Exports[exportIdx]); } catch { /* probe */ }
    string? diff = decoded?.DiffuseTexture;
    (int w, int h)? shipped = null;
    if (diff is not null)
    {
        var tex = package.Exports
            .Where(e => e.ObjectName == diff && package.GetClassName(e) == TextureReader.ClassName)
            .MaxBy(e => e.SerialSize);
        if (tex is not null)
        {
            var hdr = TextureReader.ReadHeader(package, tex);
            if (hdr is { } h) shipped = (h.Width, h.Height);
        }
    }

    Console.WriteLine($"=== {matName} ===");
    Console.WriteLine($"  surfaces {surfaces}  |Vu|med {um:0.###} |Vv|med {vm:0.###}");
    Console.WriteLine($"  distinct |Vu|: {string.Join(", ", distinctU.Take(12))}{(distinctU.Count > 12 ? " ..." : "")} (n={distinctU.Count})");
    Console.WriteLine($"  diffuse {diff}  shipped {shipped}  AuthoredTextureSize(current) {authored}");
    if (um > 0 && shipped is { } sh)
    {
        int origW = authored?.Width ?? (sh.w / 4);
        Console.WriteLine($"  period@original({origW}): {origW / um:0.###}");
        Console.WriteLine($"  period@shipped({sh.w}): {sh.w / um:0.###}");
        Console.WriteLine($"  period@shipped/2({sh.w / 2}): {sh.w / 2f / um:0.###}");
        Console.WriteLine($"  period@shipped/4({sh.w / 4}): {sh.w / 4f / um:0.###}");
        Console.WriteLine($"  period@sqrt(orig*ship)({MathF.Sqrt(origW * sh.w):0.###}): {MathF.Sqrt(origW * sh.w) / um:0.###}");
    }
}
