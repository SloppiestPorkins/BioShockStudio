#pragma once

#include "Subsystems/WorldSubsystem.h"
#include "ShockEffectsSubsystem.generated.h"

class AActor;
class AShockPlasmidFx;
class UAudioComponent;

/** Internal bookkeeping only — plain struct (not USTRUCT: nested inside no UCLASS, and
 * TWeakObjectPtr fields need no UPROPERTY reflection to stay GC-safe). */
struct FShockActiveEffect
{
	TWeakObjectPtr<AActor> Owner;
	FName Event;
	TWeakObjectPtr<AShockPlasmidFx> FxActor;
	TWeakObjectPtr<UAudioComponent> Audio;
};

/**
 * One `(EventName, EffectTag)` → presentation bundle. BioShock's real EffectsSystem additionally
 * keys on the active `EffectsSystemContext` and hit `SurfaceType` (`docs/research/
 * runtime-brain.md` §6) — the original per-(event,context,surface) authoring tables were never
 * recovered, so this port resolves on event/tag name alone (exact, then a keyword heuristic,
 * then a generic fallback) rather than leaving 167 Medical `ActionPlayEffect` calls doing
 * nothing. `ActionSetEffectsSystemContext` still pushes a real context onto
 * `UShockEffectsSubsystem`'s stack so a future context-aware bundle table has something to read.
 */
USTRUCT(BlueprintType)
struct BIOSHOCKRUNTIME_API FShockEffectBundle
{
	GENERATED_BODY()

	/** Forwarded to AShockPlasmidFx::SpawnBurst — real Niagara system if authored, else that
	 * actor's emissive-orb fallback so the effect is always visible. */
	UPROPERTY(EditAnywhere, Category = "BioShock|Effects")
	FString NiagaraAssetPath;

	UPROPERTY(EditAnywhere, Category = "BioShock|Effects")
	FLinearColor Tint = FLinearColor::White;

	UPROPERTY(EditAnywhere, Category = "BioShock|Effects")
	float LifeSeconds = 0.6f;

	UPROPERTY(EditAnywhere, Category = "BioShock|Effects")
	float Radius = 24.0f;

	/** Looked up via UShockAudioLibrary::LoadCue — NAME_None or an unresolved name plays no
	 * sound (never fabricates a cue that was not actually imported). */
	UPROPERTY(EditAnywhere, Category = "BioShock|Effects")
	FName SoundCueName;

	/** Empty = no decal. */
	UPROPERTY(EditAnywhere, Category = "BioShock|Effects")
	FString DecalMaterialPath;

	UPROPERTY(EditAnywhere, Category = "BioShock|Effects")
	FVector DecalSize = FVector(4.0f, 24.0f, 24.0f);
};

UCLASS()
class BIOSHOCKRUNTIME_API UShockEffectsSubsystem : public UWorldSubsystem
{
	GENERATED_BODY()

public:
	static UShockEffectsSubsystem* Get(const UWorld* World);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Effects", meta = (WorldContext = "WorldContextObject"))
	static UShockEffectsSubsystem* GetForWorld(UObject* WorldContextObject);

	/** Resolves a bundle for (Event, Tag) and spawns it attached to Target's root component.
	 * Returns the number of presentation elements actually spawned (0 only on a null Target). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Effects")
	int32 PlayEffect(AActor* Target, FName Event, FName Tag);

	/** Tears down every active effect this subsystem started for (Target, Event). Returns the
	 * count torn down. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Effects")
	int32 StopEffect(AActor* Target, FName Event);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Effects")
	void PushContext(FName Context);

	/** Removes the first (topmost) matching entry, not necessarily the stack top — scripts can
	 * remove a context out of push order. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Effects")
	void RemoveContext(FName Context);

	UFUNCTION(BlueprintPure, Category = "BioShock|Effects")
	FName GetCurrentContext() const { return ContextStack.Num() > 0 ? ContextStack.Last() : NAME_None; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Effects")
	int32 GetActiveEffectCountForVerify() const { return ActiveEffects.Num(); }

	UFUNCTION(BlueprintPure, Category = "BioShock|Effects")
	FName GetLastResolvedBundleKeyForVerify() const { return LastResolvedBundleKey; }

	/** Register/override a bundle at runtime (headless verify, or a future curated data table). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Effects")
	void RegisterBundle(FName Key, const FShockEffectBundle& Bundle);

private:
	const FShockEffectBundle& ResolveBundle(FName Event, FName Tag);
	void EnsureDefaultBundles();

	UPROPERTY()
	TMap<FName, FShockEffectBundle> Bundles;

	UPROPERTY()
	TArray<FName> ContextStack;

	TArray<FShockActiveEffect> ActiveEffects;

	bool bDefaultBundlesSeeded = false;
	FName LastResolvedBundleKey;
};
