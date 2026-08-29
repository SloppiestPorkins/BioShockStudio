#include "BaseShockAI.h"

#include "EngineUtils.h"
#include "Engine/World.h"

ABaseShockAI::ABaseShockAI()
{
	SchemaClassName = TEXT("BaseShockAI");
	AutoPossessAI = EAutoPossessAI::Disabled;
}

void ABaseShockAI::ConfigureIdentity(FName InType, FName InLabel)
{
	AITypeName = InType;
	ScriptLabel = InLabel;
}

void ABaseShockAI::ScriptedAttackTarget(AShockPawn* Target)
{
	CurrentScriptedAttackTarget = Target;
}

void ABaseShockAI::AddTargetToAttackOnSight(FName InTargetLabel)
{
	if (InTargetLabel.IsNone())
	{
		return;
	}
	AttackOnSightLabels.AddUnique(InTargetLabel);
}

bool ABaseShockAI::HasAttackOnSightLabel(FName InTargetLabel) const
{
	return AttackOnSightLabels.Contains(InTargetLabel);
}

void ABaseShockAI::SetAttachmentCategoryHidden(FName Category, bool bHideAttachments)
{
	if (Category.IsNone())
	{
		return;
	}
	HiddenAttachmentCategories.FindOrAdd(Category) = bHideAttachments;
}

bool ABaseShockAI::IsAttachmentCategoryHidden(FName Category) const
{
	if (const bool* Value = HiddenAttachmentCategories.Find(Category))
	{
		return *Value;
	}
	return false;
}

void ABaseShockAI::SetWeaponVisible(bool bVisible)
{
	bWeaponVisible = bVisible;
}

TArray<ABaseShockAI*> ABaseShockAI::CollectLabeled(UWorld* World, FName Label)
{
	TArray<ABaseShockAI*> Out;
	if (!World || Label.IsNone())
	{
		return Out;
	}
	const FString Want = Label.ToString();
	for (TActorIterator<ABaseShockAI> It(World); It; ++It)
	{
		ABaseShockAI* AI = *It;
		if (!AI)
		{
			continue;
		}
#if WITH_EDITOR
		if (AI->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
		{
			Out.Add(AI);
			continue;
		}
#endif
		if (AI->GetScriptLabel().ToString().Equals(Want, ESearchCase::CaseSensitive))
		{
			Out.Add(AI);
		}
	}
	return Out;
}
