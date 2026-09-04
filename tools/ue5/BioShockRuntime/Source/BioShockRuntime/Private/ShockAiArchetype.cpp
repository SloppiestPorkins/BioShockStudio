#include "ShockAiArchetype.h"

#include "BaseShockAI.h"
#include "AssetRegistry/AssetRegistryModule.h"
#include "Components/SkeletalMeshComponent.h"
#include "Engine/SkeletalMesh.h"
#include "Modules/ModuleManager.h"

namespace
{
constexpr TCHAR ContentRoot[] = TEXT("/Game/BioShockArchetypes");

UShockAiArchetype* LoadAtPath(const FString& ObjectPath)
{
	return LoadObject<UShockAiArchetype>(nullptr, *ObjectPath);
}

int32 ScoreArchetypeMatch(const UShockAiArchetype* Archetype, const FString& KeyStr)
{
	if (!Archetype)
	{
		return -1;
	}

	if (Archetype->ArchetypeName.ToString().Equals(KeyStr, ESearchCase::CaseSensitive))
	{
		return 1000;
	}

	if (!Archetype->MeshPath.Equals(KeyStr, ESearchCase::CaseSensitive))
	{
		return -1;
	}

	int32 Score = 100;
	if (Archetype->bHasHealth)
	{
		Score += 10;
	}
	if (Archetype->ArchetypeName.ToString().StartsWith(TEXT("Medical"), ESearchCase::CaseSensitive))
	{
		Score += 5;
	}
	if (Archetype->AITypeClassName.Contains(TEXT("Melee"), ESearchCase::IgnoreCase))
	{
		Score += 3;
	}
	return Score;
}
}

UShockAiArchetype* UShockAiArchetypeLibrary::FindByKey(FName Key)
{
	if (Key.IsNone())
	{
		return nullptr;
	}

	const FString KeyStr = Key.ToString();
	const FString DirectObjectPath = FString::Printf(TEXT("%s/%s.%s"), ContentRoot, *KeyStr, *KeyStr);
	if (UShockAiArchetype* Direct = LoadAtPath(DirectObjectPath))
	{
		return Direct;
	}

	FAssetRegistryModule& AssetRegistryModule =
		FModuleManager::LoadModuleChecked<FAssetRegistryModule>(TEXT("AssetRegistry"));
	TArray<FAssetData> Assets;
	AssetRegistryModule.Get().GetAssetsByPath(ContentRoot, Assets, true);
	UShockAiArchetype* Best = nullptr;
	int32 BestScore = -1;
	for (const FAssetData& AssetData : Assets)
	{
		if (AssetData.AssetClassPath.GetAssetName() != TEXT("ShockAiArchetype"))
		{
			continue;
		}

		UShockAiArchetype* Archetype = Cast<UShockAiArchetype>(AssetData.GetAsset());
		if (!Archetype)
		{
			Archetype = Cast<UShockAiArchetype>(AssetData.FastGetAsset());
		}
		if (!Archetype)
		{
			continue;
		}

		const int32 Score = ScoreArchetypeMatch(Archetype, KeyStr);
		if (Score > BestScore)
		{
			BestScore = Score;
			Best = Archetype;
		}
	}

	return Best;
}

void UShockAiArchetypeLibrary::ApplyToAI(ABaseShockAI* AI, const UShockAiArchetype* Archetype)
{
	if (!AI || !Archetype)
	{
		return;
	}

	if (!Archetype->AITypeClassName.IsEmpty())
	{
		AI->AITypeName = FName(*Archetype->AITypeClassName);
	}

	if (Archetype->bHasHealth)
	{
		AI->AuthoredHealth = Archetype->Health;
		AI->AuthoredMaxHealth = Archetype->Health;
		AI->CurrentHealth = 0.0f;
		AI->bIsDead = false;
	}

	if (Archetype->bHasFrozenHealth)
	{
		AI->AuthoredFrozenHealth = Archetype->FrozenHealth;
		AI->bHasAuthoredFrozenHealth = true;
	}

	if (!Archetype->MeshAssetPath.IsNull())
	{
		if (USkeletalMesh* MeshAsset = Cast<USkeletalMesh>(Archetype->MeshAssetPath.TryLoad()))
		{
			if (USkeletalMeshComponent* Body = AI->GetMesh())
			{
				ABaseShockAI::ApplyCombatSkeletalMesh(Body, MeshAsset, /*bDisableMeshCollision*/ true);
			}
		}
	}
}
