#pragma once

#include "CoreMinimal.h"

class AActor;
class UWorld;
class UObject;

/**
 * Shared generic-reflection plumbing for the three UnrealScript `Scripting.U` actions that read
 * or write an arbitrary actor property by name (`ActionSetProperty` / `ActionGetProperty` /
 * `ActionPropertyTest` — R2.1, `docs/research/runtime-brain.md` §4, 134 Medical script uses).
 *
 * BioShock's property path is flat (`Object.Property` on an `AActor`). Our UE port is
 * component-based, so a path may additionally step into ONE component first
 * (`"StaticMeshComponent.Mobility"`, matched by component class name or instance name) before
 * naming the `FProperty` — plain `"Property"` still resolves directly on the actor, which is
 * the 1:1 BioShock case.
 */
namespace ShockScriptReflection
{
	/** Actor lookup shared with every reflection action: editor label, AI script label
	 * (`UShockDamageLibrary::FindActorByLabel`), or a `BioShockKey=`/plain tag fallback
	 * (`UShockPhysicsLibrary::FindActorByLabel`, reused here rather than duplicated). */
	BIOSHOCKRUNTIME_API AActor* ResolveTargetActor(UWorld* World, FName Label);

	/** Splits "Component.Property" (one level) or a bare "Property" path. Returns the object the
	 * FProperty should be looked up on (the actor itself, or a matched component) and writes the
	 * remaining property name to OutPropertyName. Returns nullptr if a dotted path names a
	 * component that does not exist on Target — callers must treat that as failure, not a
	 * silent fall-back to the actor. */
	BIOSHOCKRUNTIME_API UObject* ResolvePropertyContainer(
		AActor* Target, const FString& PropertyPath, FString& OutPropertyName);

	/** Refuses Engine archetypes/CDOs and Transient/EditorOnly/Deprecated properties — script
	 * data should never poke a shared default object or a property with no gameplay meaning. */
	BIOSHOCKRUNTIME_API bool IsPropertyWritable(
		UObject* Container, FProperty* Property, FString* OutReason = nullptr);

	/** Text -> FProperty::ImportText_Direct on Target (optionally via one component step).
	 * false on: actor null, property not found, the writability guard, or a parse failure. */
	BIOSHOCKRUNTIME_API bool SetPropertyFromText(
		AActor* Target, const FString& PropertyPath, const FString& ValueText,
		FString* OutError = nullptr);

	/** FProperty::ExportTextItem_Direct -> text. false on actor null or property not found. */
	BIOSHOCKRUNTIME_API bool GetPropertyAsText(
		AActor* Target, const FString& PropertyPath, FString& OutText);
}
