using System.Numerics;
using System.Text;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Skeleton;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Scratch probe: re-test the additive interpretation of animation locals against the head-frame
/// lateral axis. The original rejection of it used the body-frame metric, which is now known to be
/// invalid, so the evidence against it has to be re-taken. Writes to <c>BIOSHOCK_ARMPROBE</c>.
/// </summary>
[Collection(GameCollection.Name)]
public sealed class ArmChainProbeTests(GameFixture game)
{
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

    /// <summary>Composes a frame, either replacing the bind local or applying the track on top of it.</summary>
    private static Matrix4x4[] PoseAt(
        BioShockSkeleton s, Core.Animation.DecodedAnimation animation, int frame, bool additive)
    {
        var byBone = new Core.Animation.DecodedTrack?[s.BoneCount];
        foreach (var track in animation.Tracks)
            if (track.TargetBoneIndex >= 0 && track.TargetBoneIndex < s.BoneCount)
                byBone[track.TargetBoneIndex] = track;

        var g = new Matrix4x4[s.BoneCount];
        for (int b = 0; b < s.BoneCount; b++)
        {
            var bone = s.Bones[b];
            var t = byBone[b];

            var tr = t is not null && frame < t.Translations.Length ? t.Translations[frame] : bone.LocalTranslation;
            var ro = t is not null && frame < t.Rotations.Length ? t.Rotations[frame] : bone.LocalRotation;
            var sc = t is not null && frame < t.Scales.Length ? t.Scales[frame] : bone.LocalScale;

            var local = Matrix4x4.CreateScale(sc) * Matrix4x4.CreateFromQuaternion(ro) * Matrix4x4.CreateTranslation(tr);

            if (additive && t is not null)
            {
                var bind = Matrix4x4.CreateScale(bone.LocalScale)
                           * Matrix4x4.CreateFromQuaternion(bone.LocalRotation)
                           * Matrix4x4.CreateTranslation(bone.LocalTranslation);
                local = local * bind;
            }

            int p = bone.ParentIndex;
            g[b] = p >= 0 && p < b ? local * g[p] : local;
        }
        return g;
    }

    private static Vector3 ViewLeft(BioShockSkeleton s, Matrix4x4[] g)
    {
        var m = g[Index(s, "Bip01_Head")];
        return Vector3.Normalize(new Vector3(m.M31, m.M32, m.M33));
    }

    [RequiresGameFact]
    public void Probe()
    {
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_ARMPROBE");
        if (string.IsNullOrWhiteSpace(target)) return;

        var sb = new StringBuilder();
        string gauntlet = Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "7-Gauntlet.bsm");

        sb.AppendLine("Additive (anim_local * bind_local) against replacement, judged on the head-frame");
        sb.AppendLine("lateral axis. Bone lengths are checked too: an additive read that stretched the");
        sb.AppendLine("skeleton would be disqualified whatever the sides did.");
        sb.AppendLine();

        // ---- first person, the arm chain laterally ----
        {
            var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");
            var s = hands.Skeleton;
            int head = Index(s, "Bip01_Head");
            string[] bones = ["Bip01_L_Clavicle", "Bip01_L_UpperArm", "Bip01_L_Hand",
                              "Bip01_R_Clavicle", "Bip01_R_UpperArm", "Bip01_R_Hand", "R_grip"];

            foreach (string animationName in new[] { "FidgetCrossbow", "FidgetPistol" })
            {
                var decoded = hands.Decode(hands.Find(animationName)!);
                foreach (bool additive in new[] { false, true })
                {
                    var g = PoseAt(s, decoded, 0, additive);
                    var left = ViewLeft(s, g);
                    var eye = g[head].Translation;
                    sb.Append($"  {animationName,-16} {(additive ? "ADDITIVE " : "replace  ")}");
                    foreach (string bone in bones)
                        sb.Append($" {bone.Replace("Bip01_", "")} {Vector3.Dot(g[Index(s, bone)].Translation - eye, left),7:0.0}");
                    sb.AppendLine();
                }
            }
            sb.AppendLine();

            // Rigidity: does the additive read preserve every bone length?
            foreach (bool additive in new[] { false, true })
            {
                float worst = 0f; string at = "";
                foreach (var animation in hands.Animations.Take(30))
                {
                    var decoded = hands.Decode(animation);
                    for (int frame = 0; frame < decoded.FrameCount; frame += 5)
                    {
                        var g = PoseAt(s, decoded, frame, additive);
                        for (int b = 0; b < s.BoneCount; b++)
                        {
                            int p = s.Bones[b].ParentIndex;
                            if (p < 0) continue;
                            float bind = s.Bones[b].LocalTranslation.Length();
                            float now = (g[b].Translation - g[p].Translation).Length();
                            if (MathF.Abs(now - bind) > worst) { worst = MathF.Abs(now - bind); at = $"{animation.Name} {s.Bones[b].Name}"; }
                        }
                    }
                }
                sb.AppendLine($"  first-person bone-length drift, {(additive ? "ADDITIVE" : "replace ")}: {worst,8:0.###} cm  ({at})");
            }
        }

        // ---- proven characters: additive must not break them ----
        sb.AppendLine();
        foreach (string name in new[] { "UAPW_AggressorBabyJane", "UAPW_GathererGirl" })
        {
            AnimationPackage pack;
            try { pack = Load(gauntlet, name); } catch { continue; }
            var s = pack.Skeleton;
            if (Index(s, "Bip01_Head") < 0) continue;
            int lh = Index(s, "Bip01_L_Hand"), rh = Index(s, "Bip01_R_Hand");
            if (lh < 0 || rh < 0) continue;

            foreach (bool additive in new[] { false, true })
            {
                int frames = 0, wrong = 0;
                float drift = 0f;
                foreach (var animation in pack.Animations.Take(40))
                {
                    var decoded = pack.Decode(animation);
                    for (int frame = 0; frame < decoded.FrameCount; frame += 5)
                    {
                        var g = PoseAt(s, decoded, frame, additive);
                        frames++;
                        if (Vector3.Dot(g[lh].Translation - g[rh].Translation, ViewLeft(s, g)) < 0f) wrong++;
                        for (int b = 0; b < s.BoneCount; b++)
                        {
                            int p = s.Bones[b].ParentIndex;
                            if (p < 0) continue;
                            drift = MathF.Max(drift, MathF.Abs(
                                (g[b].Translation - g[p].Translation).Length() - s.Bones[b].LocalTranslation.Length()));
                        }
                    }
                }
                sb.AppendLine($"  {name,-26} {(additive ? "ADDITIVE" : "replace ")}: hands wrong on {wrong,6}/{frames,-6} frames," +
                              $" worst bone-length drift {drift,8:0.###} cm");
            }
        }

        File.WriteAllText(target, sb.ToString());
    }
}
