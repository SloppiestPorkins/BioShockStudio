using System.Buffers.Binary;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Assets;

/// <summary>One timed event on an animation.</summary>
public sealed record AnimationEvent
{
    /// <summary>Seconds from the start of the animation.</summary>
    public required float Time { get; init; }

    /// <summary>The notify object this event fires, e.g. <c>AnimNotify_EffectEvent53</c>.</summary>
    public required string NotifyObject { get; init; }

    /// <summary>The notify's class, e.g. <c>AnimNotify_EffectEvent</c>.</summary>
    public required string NotifyClass { get; init; }

    /// <summary>The named event, e.g. <c>ReloadPistolOne</c>. Empty when the notify carries no name.</summary>
    public required string EventName { get; init; }

    public override string ToString() => $"{Time:0.###}s {EventName} ({NotifyClass})";
}

/// <summary>
/// Reads <c>SharedSkeletonAnimationMetadata</c>, the per-animation event track.
/// <para>
/// CONFIRMED_BYTES against <c>NEWPlayerHands</c>: there is exactly one metadata object per
/// animation (130 of each), every event time falls inside its animation's duration, and the
/// references resolve to <c>AnimNotify</c> exports whose names match the gameplay
/// (<c>FastReloadPistol</c> fires <c>ReloadPistolOne/Two/Three</c> at 0.30 s, 1.06 s and 1.53 s
/// against a 1.80 s animation).
/// </para>
/// <code>
/// +0   18 bytes  header shared with other BioShock export payloads
/// +18  13 bytes  UNKNOWN
/// +31  byte      event count
///      per event: float time, FCompactIndex PackageIndex of the notify object
/// </code>
/// <para>
/// UNKNOWN: bytes +18..+30, and the trailing data after the event list.
/// </para>
/// </summary>
public static class AnimationMetadataReader
{
    /// <summary>Prefix used by the per-animation metadata objects.</summary>
    public const string ObjectPrefix = "USharedSkeletonAnimationMetadata_";

    public const string ClassName = "SharedSkeletonAnimationMetadata";

    private const int EventCountOffset = 31;

    /// <summary>Reads the event track. Returns an empty list when the object carries no events.</summary>
    public static IReadOnlyList<AnimationEvent> ReadEvents(
        BioShockPackage package, ObjectExport metadataExport, float animationDuration)
    {
        byte[] payload = package.ReadExportData(metadataExport);
        if (payload.Length <= EventCountOffset) return [];

        int count = payload[EventCountOffset];
        if (count is 0 or > 64) return [];

        var events = new List<AnimationEvent>(count);
        int offset = EventCountOffset + 1;

        for (int i = 0; i < count; i++)
        {
            if (offset + 5 > payload.Length) break;

            float time = BinaryPrimitives.ReadSingleLittleEndian(payload.AsSpan(offset));
            offset += 4;
            int reference = ReadCompactIndex(payload, ref offset);

            // An event outside its own animation means the layout has drifted, so stop rather than
            // emit nonsense.
            if (!float.IsFinite(time) || time < -0.001f || time > animationDuration + 0.001f) break;

            var notify = ResolveExport(package, reference);
            if (notify is null) break;

            events.Add(new AnimationEvent
            {
                Time = time,
                NotifyObject = notify.ObjectName,
                NotifyClass = package.GetClassName(notify),
                EventName = ReadEventName(package, notify),
            });
        }

        return events;
    }

    private static ObjectExport? ResolveExport(BioShockPackage package, int packageIndex)
    {
        if (packageIndex <= 0) return null;
        int index = packageIndex - 1;
        return index < package.Exports.Count ? package.Exports[index] : null;
    }

    /// <summary>The notify's <c>EffectEvent</c> name property, when it has one.</summary>
    private static string ReadEventName(BioShockPackage package, ObjectExport notify)
    {
        try
        {
            byte[] payload = package.ReadExportData(notify);
            var properties = UnrealPropertyReader.Read(payload, package.Names, out _);

            foreach (var property in properties)
            {
                if (property.Type != UnrealPropertyType.Name) continue;
                int offset = 0;
                int nameIndex = ReadCompactIndex(property.Value, ref offset);
                if (nameIndex >= 0 && nameIndex < package.Names.Count) return package.Names[nameIndex].Name;
            }
        }
        catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException or InvalidDataException)
        {
            // A notify we cannot read still has a valid time and object name.
        }

        return string.Empty;
    }

    private static int ReadCompactIndex(ReadOnlySpan<byte> data, ref int offset)
    {
        byte b = data[offset++];
        bool negative = (b & 0x80) != 0;
        int value = b & 0x3F;

        if ((b & 0x40) != 0)
        {
            int shift = 6;
            while (true)
            {
                byte c = data[offset++];
                value |= (c & 0x7F) << shift;
                shift += 7;
                if ((c & 0x80) == 0) break;
                if (shift > 31) throw new InvalidDataException("FCompactIndex overflow.");
            }
        }

        return negative ? -value : value;
    }
}
