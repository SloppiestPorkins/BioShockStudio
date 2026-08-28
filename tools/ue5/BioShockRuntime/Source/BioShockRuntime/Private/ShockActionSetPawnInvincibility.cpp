#include "ShockActionSetPawnInvincibility.h"

#include "BaseShockAI.h"
#include "EngineUtils.h"
#include "ShockPawn.h"

UShockActionSetPawnInvincibility::UShockActionSetPawnInvincibility()
{
	ActionClassName = TEXT("ActionSetPawnInvincibility");
	bInvincible = true;
}

void UShockActionSetPawnInvincibility::Configure(FName InPawn, bool bInInvincible)
{
	PawnLabel = InPawn;
	bInvincible = bInInvincible;
}

bool UShockActionSetPawnInvincibility::RequestSet()
{
	if (PawnLabel.IsNone())
	{
		return false;
	}
	LastPawnLabel = PawnLabel;
	return true;
}

int32 UShockActionSetPawnInvincibility::ApplyInWorld(UWorld* World)
{
	if (!RequestSet() || !World)
	{
		return 0;
	}
	int32 Applied = 0;
	const FString Want = PawnLabel.ToString();
	for (TActorIterator<AShockPawn> It(World); It; ++It)
	{
		AShockPawn* Pawn = *It;
		if (!Pawn)
		{
			continue;
		}
		bool bMatch = false;
#if WITH_EDITOR
		bMatch = Pawn->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive);
#endif
		if (!bMatch)
		{
			if (const ABaseShockAI* AI = Cast<ABaseShockAI>(Pawn))
			{
				bMatch = AI->GetScriptLabel().ToString().Equals(Want, ESearchCase::CaseSensitive);
			}
		}
		if (!bMatch)
		{
			continue;
		}
		Pawn->SetInvincible(bInvincible);
		++Applied;
	}
	return Applied;
}
