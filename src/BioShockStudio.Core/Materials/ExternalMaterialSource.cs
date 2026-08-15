namespace BioShockStudio.Core.Materials;

/// <summary>
/// Finds a material a mesh names by <b>import</b> — one that lives in a different package file.
/// </summary>
/// <remarks>
/// <para>
/// 433 of the game's material slots are imports, and <b>not one of them resolves inside its own
/// package</b>. They are the shared shaders: every <c>WP_AI_*</c> weapon a splicer carries points at
/// the viewmodel's shader in <c>ShockGame.U</c>, the ammo pickups point at the weapon packages, and
/// all 108 security-camera slots point at <c>cam_smallcam_shader</c> in <c>ShockAI.U</c>. Without a
/// cross-package lookup every one of those meshes draws flat grey, which is exactly what the
/// security cameras, the turret pickups and every socketed NPC weapon did.
/// </para>
/// <para>
/// The import states two things: the object's name, and — through its outer — the <b>group</b> it
/// belongs to (<c>WP_Pistol</c>, <c>MA_Security</c>, <c>FX_tex</c>). Both are used, because this
/// project has already been bitten once by resolving a shared name without its group: 112 texture
/// names appear in more than one bulk group and all 112 are different art. A name-only match is
/// accepted as a fallback and is reported as the weaker result it is.
/// </para>
/// </summary>
public interface IExternalMaterialSource
{
    /// <summary>
    /// The material with this name, preferring one whose group matches.
    /// </summary>
    /// <param name="objectName">The imported object's name, e.g. <c>PistolShader</c>.</param>
    /// <param name="group">
    /// The group the import's outer names, e.g. <c>WP_Pistol</c>. Empty when the chain does not
    /// resolve to one, in which case only the name is matched.
    /// </param>
    /// <returns>Null when nothing of that name exists in any package — which is honest, not a bug.</returns>
    BioShockMaterial? Find(string objectName, string group);
}
