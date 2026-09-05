namespace BioShockStudio.Core.UI.Swf;

/// <summary>One PlaceObject2 record: which character goes at which depth, with what transform.</summary>
public readonly record struct SwfPlaceObject(int Depth, int? CharacterId, SwfMatrix? Matrix, bool Move);

public static class SwfPlaceObjectReader
{
    /// <summary>PlaceObject2 (tag 26) only — the only PlaceObject variant any checked BioShock
    /// UI file uses (all SWF version 6; PlaceObject3 is an SWF8+ tag, PlaceObject1 predates the
    /// depth/matrix/character flags model this reads).</summary>
    public static SwfPlaceObject ReadPlaceObject2(byte[] body)
    {
        int pos = 0;
        int flags = body[pos];
        pos += 1;
        bool hasClipActions = (flags & 0x80) != 0;
        bool hasClipDepth = (flags & 0x40) != 0;
        bool hasName = (flags & 0x20) != 0;
        bool hasRatio = (flags & 0x10) != 0;
        bool hasColorTransform = (flags & 0x08) != 0;
        bool hasMatrix = (flags & 0x04) != 0;
        bool hasCharacter = (flags & 0x02) != 0;
        bool move = (flags & 0x01) != 0;

        int depth = System.Buffers.Binary.BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
        pos += 2;

        int? characterId = null;
        if (hasCharacter)
        {
            characterId = System.Buffers.Binary.BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
            pos += 2;
        }

        SwfMatrix? matrix = null;
        if (hasMatrix)
        {
            var bits = new SwfBitReader(body.AsSpan(pos));
            matrix = SwfMatrixReader.Read(ref bits);
            pos += bits.BytePosition;
        }

        // Nothing after this point (ColorTransform/Ratio/Name/ClipDepth/ClipActions) matters for
        // composition — depth + character + matrix is everything a static-first-frame render
        // needs. Not parsed further.
        _ = hasClipActions; _ = hasClipDepth; _ = hasName; _ = hasRatio; _ = hasColorTransform;

        return new SwfPlaceObject(depth, characterId, matrix, move);
    }
}
