using System.Numerics;
using System.Text;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Skeleton;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Scratch experiment harness for the first-person arm blocker, run in an isolated worktree.
/// <para>
/// Every candidate is scored against ALL the constraints at once, because the project's own history
/// is that a sign test alone is satisfied by several wrong changes. A candidate is only interesting
/// if it fixes the first-person sides, leaves the proven characters exactly where they are, and
/// keeps every bone at its bind length.
/// </para>
/// Writes to <c>BIOSHOCK_EXPERIMENT</c> and does nothing otherwise. Nothing here touches Core.
/// </summary>
[Collection(GameCollection.Name)]
public sealed class ArmExperimentTests(GameFixture game)
{
    private sealed record Local(Vector3 T, Quaternion R, Vector3 S);

    /// <summary>Reflection in the plane whose normal is the rig's local Z, in a parent-local frame.</summary>
    private static Vector3 MirrorZ(Vector3 t) => new(t.X, t.Y, -t.Z);
    private static Quaternion MirrorZ(Quaternion q) => new(-q.X, -q.Y, q.Z, q.W);
    private static Local MirrorZ(Local l) => new(MirrorZ(l.T), MirrorZ(l.R), l.S);

    private AnimationPackage Load(string packagePath, string objectName)
    {
        using var package = BioShockPackage.Open(packagePath);
        var export = package.Exports
            .Where(e => e.ObjectName == objectName
                        && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
            .MaxBy(e => e.SerialSize);
        return AnimationPackage.Load(package, export!);
    }

    private static int Index(BioShockSkeleton s, string name)
    {
        for (int i = 0; i < s.Bones.Count; i++)
            if (string.Equals(s.Bones[i].Name, name, StringComparison.OrdinalIgnoreCase)) return i;
        return -1;
    }

    private static Local[] LocalsAt(BioShockSkeleton s, Core.Animation.DecodedAnimation a, int frame)
    {
        var byBone = new Core.Animation.DecodedTrack?[s.BoneCount];
        foreach (var t in a.Tracks)
            if (t.TargetBoneIndex >= 0 && t.TargetBoneIndex < s.BoneCount) byBone[t.TargetBoneIndex] = t;

        var locals = new Local[s.BoneCount];
        for (int b = 0; b < s.BoneCount; b++)
        {
            var bone = s.Bones[b];
            var t = byBone[b];
            locals[b] = new Local(
                t is not null && frame < t.Translations.Length ? t.Translations[frame] : bone.LocalTranslation,
                t is not null && frame < t.Rotations.Length ? t.Rotations[frame] : bone.LocalRotation,
                t is not null && frame < t.Scales.Length ? t.Scales[frame] : bone.LocalScale);
        }
        return locals;
    }

    private static Matrix4x4[] Compose(BioShockSkeleton s, Local[] locals)
    {
        var g = new Matrix4x4[s.BoneCount];
        for (int b = 0; b < s.BoneCount; b++)
        {
            var m = Matrix4x4.CreateScale(locals[b].S)
                    * Matrix4x4.CreateFromQuaternion(locals[b].R)
                    * Matrix4x4.CreateTranslation(locals[b].T);
            int p = s.Bones[b].ParentIndex;
            g[b] = p >= 0 && p < b ? m * g[p] : m;
        }
        return g;
    }

    /// <summary>Lateral axis: the clavicle separation, which is the head's +Z at dot 1.00.</summary>
    private static Vector3 Lateral(BioShockSkeleton s, Matrix4x4[] g)
    {
        int lc = Index(s, "Bip01_L_Clavicle"), rc = Index(s, "Bip01_R_Clavicle");
        return Vector3.Normalize(g[lc].Translation - g[rc].Translation);
    }

    private static float LengthDrift(BioShockSkeleton s, Matrix4x4[] g)
    {
        float worst = 0f;
        for (int b = 0; b < s.BoneCount; b++)
        {
            int p = s.Bones[b].ParentIndex;
            if (p < 0) continue;
            worst = MathF.Max(worst,
                MathF.Abs((g[b].Translation - g[p].Translation).Length() - s.Bones[b].LocalTranslation.Length()));
        }
        return worst;
    }

    /// <summary>The arm bones below the clavicle, both sides, paired.</summary>
    private static readonly string[] ArmParts = ["UpperArm", "Forearm", "Hand"];

    [RequiresGameFact]
    public void Probe()
    {
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_EXPERIMENT");
        if (string.IsNullOrWhiteSpace(target)) return;

        var sb = new StringBuilder();
        var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");
        string gauntlet = Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "7-Gauntlet.bsm");

        // Each candidate rewrites the composed locals for one frame.
        var candidates = new (string Name, Action<BioShockSkeleton, Local[]> Apply)[]
        {
            ("baseline (as decoded)", (_, _) => { }),

            ("mirrorZ the RIGHT arm's animated locals", (s, l) =>
                { foreach (var p in ArmParts) { int i = Index(s, "Bip01_R_" + p); if (i >= 0) l[i] = MirrorZ(l[i]); } }),

            ("mirrorZ the LEFT arm's animated locals", (s, l) =>
                { foreach (var p in ArmParts) { int i = Index(s, "Bip01_L_" + p); if (i >= 0) l[i] = MirrorZ(l[i]); } }),

            ("mirrorZ BOTH arms' animated locals", (s, l) =>
                { foreach (var p in ArmParts) foreach (string side in new[] { "L", "R" })
                    { int i = Index(s, $"Bip01_{side}_" + p); if (i >= 0) l[i] = MirrorZ(l[i]); } }),

            ("mirrorZ both CLAVICLE animated rotations", (s, l) =>
                { foreach (string side in new[] { "L", "R" })
                    { int i = Index(s, $"Bip01_{side}_Clavicle"); if (i >= 0) l[i] = MirrorZ(l[i]); } }),

            ("mirrorZ the RIGHT clavicle only", (s, l) =>
                { int i = Index(s, "Bip01_R_Clavicle"); if (i >= 0) l[i] = MirrorZ(l[i]); }),

            ("mirrorZ the LEFT clavicle only", (s, l) =>
                { int i = Index(s, "Bip01_L_Clavicle"); if (i >= 0) l[i] = MirrorZ(l[i]); }),

            ("swap the two arms' animated locals", (s, l) =>
                { foreach (var p in ArmParts)
                    { int a = Index(s, "Bip01_L_" + p), b = Index(s, "Bip01_R_" + p);
                      if (a >= 0 && b >= 0) (l[a], l[b]) = (l[b], l[a]); } }),

            ("mirrorZ AND swap the two arms", (s, l) =>
                { foreach (var p in ArmParts)
                    { int a = Index(s, "Bip01_L_" + p), b = Index(s, "Bip01_R_" + p);
                      if (a >= 0 && b >= 0) (l[a], l[b]) = (MirrorZ(l[b]), MirrorZ(l[a])); } }),

            ("mirrorZ the RIGHT arm, clavicle included", (s, l) =>
                { foreach (var p in ArmParts.Append("Clavicle"))
                    { int i = Index(s, "Bip01_R_" + p); if (i >= 0) l[i] = MirrorZ(l[i]); } }),
        };

        sb.AppendLine("Lateral separation L-R down the chain, in the rig's own clavicle axis.");
        sb.AppendLine("Correct looks like the control: positive and growing. drift = worst bone-length");
        sb.AppendLine("change from bind, which must stay at 0.");
        sb.AppendLine();

        void Run(string label, AnimationPackage pack, string animationName)
        {
            var s = pack.Skeleton;
            var found = pack.Find(animationName);
            if (found is null) { sb.AppendLine($"  {animationName}: not found"); return; }
            var decoded = pack.Decode(found);

            sb.AppendLine($"--- {label} / {animationName} ---");
            sb.AppendLine($"    {"candidate",-44} {"clav",8} {"upper",8} {"fore",8} {"hand",8}  {"drift",8}");

            foreach (var (name, apply) in candidates)
            {
                var locals = LocalsAt(s, decoded, 0);
                apply(s, locals);
                var g = Compose(s, locals);
                var lateral = Lateral(s, g);

                float Side(string part)
                {
                    int a = Index(s, "Bip01_L_" + part), b = Index(s, "Bip01_R_" + part);
                    return a < 0 || b < 0 ? float.NaN : Vector3.Dot(g[a].Translation - g[b].Translation, lateral);
                }

                sb.AppendLine($"    {name,-44} {Side("Clavicle"),8:0.00} {Side("UpperArm"),8:0.00}" +
                              $" {Side("Forearm"),8:0.00} {Side("Hand"),8:0.00}  {LengthDrift(s, g),8:0.###}");
            }
            sb.AppendLine();
        }

        Run("FIRST PERSON", hands, "FidgetCrossbow");
        Run("FIRST PERSON", hands, "FidgetPistol");
        Run("CONTROL", Load(gauntlet, "UAPW_AggressorBabyJane"), "Fidget_Burning");

        File.WriteAllText(target, sb.ToString());
    }
}
