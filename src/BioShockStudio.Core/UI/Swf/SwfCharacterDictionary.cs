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
    private readonly Dictionary<int, SwfFont> _fonts = new();
    private readonly Dictionary<int, SwfTextRun> _textRuns = new();
    private readonly List<(int Id, string Name)> _exportNames = new();

    /// <summary>Every (id, name) pair this file's ExportAssets tags declare — the same names
    /// visible in an authoring tool's Library panel (e.g. "FrozenHealth_DangerBar"), and the only
    /// practical way to find a specific real UI element without already knowing its numeric ID.</summary>
    public IReadOnlyList<(int Id, string Name)> ExportNames => _exportNames;

    public static SwfCharacterDictionary Build(SwfFile file)
    {
        var dict = new SwfCharacterDictionary();
        foreach (SwfTag tag in file.Tags)
        {
            if (tag.Code == 56) // ExportAssets
            {
                int pos = 2; // Count: U16, already implied by walking until tag.Body ends.
                byte[] body = tag.Body;
                int count = System.Buffers.Binary.BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(0, 2));
                for (int i = 0; i < count && pos < body.Length; i++)
                {
                    int id = System.Buffers.Binary.BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
                    pos += 2;
                    int start = pos;
                    while (pos < body.Length && body[pos] != 0) pos++;
                    string name = System.Text.Encoding.UTF8.GetString(body, start, pos - start);
                    pos += 1; // null terminator
                    dict._exportNames.Add((id, name));
                }
                continue;
            }
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
            else if (tag.Code is 48 or 75) // DefineFont2/3
            {
                try
                {
                    SwfFont font = SwfFontReader.Read(tag.Body, tag.Code);
                    dict._fonts[font.FontId] = font;
                }
                catch (Exception)
                {
                    // Same reasoning as the shape catch above — an unparseable font just can't
                    // back any text run that references it.
                }
            }
            else if (tag.Code is 11 or 33) // DefineText/DefineText2
            {
                try
                {
                    SwfTextRun run = SwfTextReader.Read(tag.Body, tag.Code);
                    dict._textRuns[run.CharacterId] = run;
                }
                catch (Exception)
                {
                    // Same reasoning again — an unparseable text run just isn't placeable.
                }
            }
        }
        return dict;
    }

    public bool TryGetShape(int characterId, out SwfShape shape) => _shapes.TryGetValue(characterId, out shape!);

    public bool TryGetSprite(int characterId, out IReadOnlyList<SwfTag> controlTags) =>
        _sprites.TryGetValue(characterId, out controlTags!);

    public bool TryGetFont(int fontId, out SwfFont font) => _fonts.TryGetValue(fontId, out font!);

    public bool TryGetTextRun(int characterId, out SwfTextRun run) => _textRuns.TryGetValue(characterId, out run!);

    /// <summary>Case-insensitive substring search over every ExportAssets name in this file.</summary>
    public IEnumerable<(int Id, string Name)> FindByName(string substring) =>
        _exportNames.Where(e => e.Name.Contains(substring, StringComparison.OrdinalIgnoreCase));
}
