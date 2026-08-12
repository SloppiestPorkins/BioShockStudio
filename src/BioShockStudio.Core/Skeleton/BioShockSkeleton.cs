using System.Numerics;

namespace BioShockStudio.Core.Skeleton;

/// <summary>
/// One bone. <see cref="OriginalBoneIndex"/> is the identity that matters — Havok animation tracks
/// reference bones by index, so the array order must never be re-sorted or deduplicated by name.
/// </summary>
public sealed record BioShockBone
{
    public required int OriginalBoneIndex { get; init; }
    public required string Name { get; init; }

    /// <summary>Index into the same bone array, or -1 for a root.</summary>
    public required int ParentIndex { get; init; }

    /// <summary>Reference-pose transform relative to the parent.</summary>
    public required Vector3 LocalTranslation { get; init; }

    public required Quaternion LocalRotation { get; init; }
    public required Vector3 LocalScale { get; init; }

    /// <summary>Havok's per-bone translation lock flag.</summary>
    public required bool LockTranslation { get; init; }

    public bool IsRoot => ParentIndex < 0;

    public override string ToString() => $"[{OriginalBoneIndex}] {Name}";
}

/// <summary>
/// A skeleton decoded from <c>hkaSkeleton</c>, with original bone ordering preserved.
/// </summary>
public sealed class BioShockSkeleton
{
    public required string Name { get; init; }
    public required IReadOnlyList<BioShockBone> Bones { get; init; }

    /// <summary>Source location, for diagnostics and raw export.</summary>
    public required string SourceSection { get; init; }

    public required int SourceOffset { get; init; }

    public int BoneCount => Bones.Count;

    public BioShockBone? FindBone(string name)
    {
        foreach (var bone in Bones)
            if (bone.Name == name) return bone;
        return null;
    }

    /// <summary>
    /// Reference-pose transforms composed into skeleton space, parent before child.
    /// <para>
    /// Havok skeletons are stored parent-first, so a single forward pass is sufficient; the loop
    /// still guards against a child preceding its parent rather than assuming it.
    /// </para>
    /// </summary>
    public Matrix4x4[] ComputeGlobalTransforms()
    {
        var global = new Matrix4x4[Bones.Count];

        for (int i = 0; i < Bones.Count; i++)
        {
            var bone = Bones[i];
            var local = Matrix4x4.CreateScale(bone.LocalScale)
                        * Matrix4x4.CreateFromQuaternion(bone.LocalRotation)
                        * Matrix4x4.CreateTranslation(bone.LocalTranslation);

            if (bone.ParentIndex < 0)
            {
                global[i] = local;
            }
            else if (bone.ParentIndex < i)
            {
                global[i] = local * global[bone.ParentIndex];
            }
            else
            {
                throw new InvalidDataException(
                    $"Bone '{bone.Name}' ({i}) precedes its parent ({bone.ParentIndex}); " +
                    "the skeleton is not stored parent-first.");
            }
        }

        return global;
    }

    /// <summary>Inverse bind matrices, i.e. the inverse of each global reference-pose transform.</summary>
    public Matrix4x4[] ComputeInverseBindTransforms()
    {
        var global = ComputeGlobalTransforms();
        var inverse = new Matrix4x4[global.Length];
        for (int i = 0; i < global.Length; i++)
        {
            if (!Matrix4x4.Invert(global[i], out inverse[i]))
                throw new InvalidDataException($"Bone '{Bones[i].Name}' has a non-invertible global transform.");
        }
        return inverse;
    }

    /// <summary>Renders the hierarchy for the CLI and the eventual skeleton viewer.</summary>
    public IEnumerable<string> DescribeHierarchy()
    {
        var childrenOf = new Dictionary<int, List<int>>();
        var roots = new List<int>();

        for (int i = 0; i < Bones.Count; i++)
        {
            int parent = Bones[i].ParentIndex;
            if (parent < 0) roots.Add(i);
            else (childrenOf.TryGetValue(parent, out var list) ? list : childrenOf[parent] = []).Add(i);
        }

        var lines = new List<string>();
        foreach (int root in roots) Walk(root, 0);
        return lines;

        void Walk(int index, int depth)
        {
            lines.Add($"{new string(' ', depth * 2)}[{index,2}] {Bones[index].Name}");
            if (childrenOf.TryGetValue(index, out var children))
                foreach (int child in children) Walk(child, depth + 1);
        }
    }
}
