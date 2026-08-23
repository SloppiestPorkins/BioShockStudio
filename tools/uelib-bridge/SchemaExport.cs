using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using UELib;
using UELib.Core;

namespace BioShockStudio.UELibBridge;

/// <summary>One class's schema: what it is, what it derives from, and what it declares.</summary>
public sealed record ClassSchema
{
    public required string Name { get; init; }
    public string? Super { get; init; }
    public required string Package { get; init; }

    /// <summary>Declared variables, with their UnrealScript types.</summary>
    public required IReadOnlyList<VariableSchema> Variables { get; init; }

    /// <summary>
    /// The class's <c>defaultproperties</c>, flattened to name/value pairs.
    /// </summary>
    /// <remarks>
    /// This is the half of the decompiler's output that comes out clean, and it is the whole point
    /// of this exporter: <c>CollisionRadius=50.0</c>, <c>bPrefersRangedAttack=true</c> and the rest
    /// are the game's own tuning values, usable directly rather than as documentation.
    /// </remarks>
    public required IReadOnlyList<DefaultSchema> Defaults { get; init; }
}

public sealed record VariableSchema
{
    public required string Name { get; init; }
    public required string Type { get; init; }
}

public sealed record DefaultSchema
{
    public required string Name { get; init; }
    public required string Value { get; init; }

    /// <summary>Element index for a static-array entry, or null for a scalar.</summary>
    public int? Index { get; init; }
}

/// <summary>
/// Emits every class's schema and defaults as JSON, for the UE5 port's data layer.
/// </summary>
/// <remarks>
/// <para>
/// Deliberately does <b>not</b> emit function bodies. Those decompile with control-flow artifacts
/// and <c>__NFUN_&lt;id&gt;__</c> placeholders (<c>docs/research/bytecode.md</c> §3), so they are
/// documentation for a human implementing the behaviour by hand, not machine input. Emitting them
/// here would invite exactly the automatic-transpilation approach
/// <c>docs/UE5_FULL_PORT_PLAN.md</c> argues against.
/// </para>
/// <para>
/// What it does emit is byte-backed and clean, and is what the port's data layer needs.
/// </para>
/// </remarks>
public static class SchemaExport
{
    private static readonly JsonSerializerOptions Options = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };

    public static int Run(string outputFile, string packageName, string scriptsDirectory)
    {
        string path = Path.Combine(scriptsDirectory, packageName);
        var package = UnrealLoader.LoadPackage(path, FileAccess.Read);
        package.InitializePackage();

        var schemas = new List<ClassSchema>();
        int failed = 0;

        foreach (var obj in package.Objects)
        {
            if ((int)obj <= 0) continue;
            if (obj is not UClass cls) continue;

            try
            {
                schemas.Add(new ClassSchema
                {
                    Name = cls.Name,
                    Super = cls.Super?.Name,
                    Package = packageName,
                    Variables = ReadVariables(cls),
                    Defaults = ReadDefaults(cls),
                });
            }
            catch (Exception ex)
            {
                // Reported, never silently dropped: a class missing from the schema would look like
                // a class the game does not have.
                failed++;
                Console.WriteLine($"[FAIL] {cls.Name}: {ex.Message}");
            }
        }

        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(outputFile))!);
        using (var stream = File.Create(outputFile))
        {
            JsonSerializer.Serialize(stream, schemas, Options);
        }

        int defaults = schemas.Sum(s => s.Defaults.Count);
        int variables = schemas.Sum(s => s.Variables.Count);
        Console.WriteLine(
            $"{packageName}: {schemas.Count} classes, {variables} variables, {defaults} defaults, {failed} failed -> {outputFile}");

        return failed == 0 ? 0 : 1;
    }

    private static List<VariableSchema> ReadVariables(UClass cls)
    {
        var result = new List<VariableSchema>();

        foreach (var variable in cls.Variables)
        {
            string type;
            try { type = variable.GetFriendlyType(); }
            catch (Exception ex) when (ex is NullReferenceException or InvalidOperationException)
            {
                // A type this build cannot name is still a declared variable; recording it as
                // unknown keeps the count honest rather than dropping the row.
                type = "<unresolved>";
            }

            result.Add(new VariableSchema { Name = variable.Name, Type = type });
        }

        return result;
    }

    private static List<DefaultSchema> ReadDefaults(UClass cls)
    {
        var result = new List<DefaultSchema>();
        if (cls.Properties is null) return result;

        foreach (var property in cls.Properties)
        {
            string value;
            try { value = property.Value; }
            catch (Exception ex) when (ex is NullReferenceException or InvalidOperationException
                                          or IndexOutOfRangeException or ArgumentOutOfRangeException)
            {
                // UELib has known array-type inference gaps (Emitters, Skins, EventResponse). The
                // property is still declared, so record it as unreadable rather than omitting it:
                // a missing default and an unparseable one are different facts.
                value = "<unreadable>";
            }

            result.Add(new DefaultSchema
            {
                Name = property.Name,
                Value = value,
                Index = property.ArrayIndex >= 0 ? property.ArrayIndex : null,
            });
        }

        return result;
    }
}
