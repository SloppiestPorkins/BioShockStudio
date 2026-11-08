using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;

string? root = GameLocator.Find() ?? throw new InvalidOperationException("game not found");
string map = Path.Combine(GameLocator.MapsDirectory(root), "1-Medical.bsm");
using var package = BioShockPackage.Open(map);
var context = LevelAnalyzer.Analyze(package);
var live = StaticMeshInstanceReader.EnumerateLive(package, context);
int nullInst = live.Count(x => x.Instance is null);
int mismatch = 0, undecodableMesh = 0, ok = 0;
foreach (var (actor, inst) in live)
{
    if (inst is null) continue;
    int meshVerts = StaticMeshInstanceReader.MeshVertexCount(package, inst.Mesh);
    if (meshVerts < 0) { undecodableMesh++; continue; }
    if (meshVerts != inst.VertexCount) mismatch++;
    else ok++;
}
Console.WriteLine($"live={live.Count} nullInst={nullInst} okVerts={ok} mismatch={mismatch} undecodableMesh={undecodableMesh}");
var a2234 = live.First(x => x.Actor.Source.ObjectName == "StaticMeshActor2234");
Console.WriteLine($"2234 key={a2234.Actor.Source.Key} layers={a2234.Instance!.Layers.Count} verts={a2234.Instance.VertexCount}");
