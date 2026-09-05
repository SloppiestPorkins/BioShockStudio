using System.Buffers.Binary;
using BioShockStudio.Core.UI.Swf.Shapes;

namespace BioShockStudio.Core.UI.Swf;

/// <summary>
/// Every shape and sprite definition in an SWF file, indexed by character ID, for
/// <see cref="SwfSpriteComposer"/> to resolve PlaceObject2 references against. DefineSprite
/// bodies only ever contain placement/control tags (PlaceObject/RemoveObject/ShowFrame/...),
/// never new character-definition tags — every DefineShape/DefineSprite lives in the file's own
/// top-level tag stream, so this dictionary never needs to recurse into a sprite to find one.
/// </summary>
public sealed class SwfCharacterDictionary
{
    private readonly Dictionary<int, SwfShape> _shapes = new();
    private readonly Dictionary<int, IReadOnlyList<SwfTag>> _sprites = new();

    public static SwfCharacterDictionary Build(SwfFile file)
    {
        var dict = new SwfCharacterDictionary();
        foreach (SwfTag tag in file.Tags)
        {
            if (tag.Code is 2 or 22 or 32 or 83)
            {
                try
                {
                    SwfShape shape = SwfShapeReader.Read(tag.Body, tag.Code);
                    dict._shapes[shape.CharacterId] = shape;
                }
                catch (Exception)
                {
                    // A shape this dictionary can't parse just isn't resolvable as a placement
                    // target — SwfSpriteComposer already treats an unresolved character ID as
                    // "draws nothing", the same as a genuinely unsupported tag would.
                }
            }
            else if (tag.Code == 39) // DefineSprite
            {
                int spriteId = BinaryPrimitives.ReadUInt16LittleEndian(tag.Body.AsSpan(0, 2));
                IReadOnlyList<SwfTag> controlTags = SwfFile.ReadTagStream(tag.Body, 4);
                dict._sprites[spriteId] = controlTags;
            }
        }
        return dict;
    }

    public bool TryGetShape(int characterId, out SwfShape shape) => _shapes.TryGetValue(characterId, out shape!);

    public bool TryGetSprite(int characterId, out IReadOnlyList<SwfTag> controlTags) =>
        _sprites.TryGetValue(characterId, out controlTags!);
}
