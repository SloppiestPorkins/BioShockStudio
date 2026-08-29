#pragma once

#include "Engine/DataAsset.h"
#include "ShockAiArchetype.generated.h"

class ABaseShockAI;
class USkeletalMesh;

/** One chance-weighted loadout slot from `document.archetypes`. */
USTRUCT(BlueprintType)
struct FShockAiArchetypeLoadoutSlot
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Name;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float Chance = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Replacement;
};

/**
 * One `document.archetypes` record — a faithful mirror of the level manifest export.
 * Authored in the throwaway UE5 project by `import_ai_archetypes.py`.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockAiArchetype : public UDataAsset
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ArchetypeName;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	FString AITypeClassName;

	/** Manifest `mesh` — the BioShock skeletal-mesh name, not a UE asset path. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	FString MeshPath;

	/** Resolved UE skeletal mesh, when import found one in the content browser. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	FSoftObjectPath MeshAssetPath;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float Health = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bHasHealth = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float FrozenHealth = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bHasFrozenHealth = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	FString DamageResistanceSetName;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	TArray<FShockAiArchetypeLoadoutSlot> MaterialSlots;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	TArray<FShockAiArchetypeLoadoutSlot> AttachmentSlots;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	TArray<FShockAiArchetypeLoadoutSlot> WeaponSlots;
};

UCLASS()
class BIOSHOCKRUNTIME_API UShockAiArchetypeLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	/** Resolve by archetype name or manifest `mesh` string. Missing assets return nullptr. */
	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	static UShockAiArchetype* FindByKey(FName Key);

	/** Apply archetype stats to a spawned AI. No-op when Archetype is null. */
	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	static void ApplyToAI(ABaseShockAI* AI, const UShockAiArchetype* Archetype);
};
