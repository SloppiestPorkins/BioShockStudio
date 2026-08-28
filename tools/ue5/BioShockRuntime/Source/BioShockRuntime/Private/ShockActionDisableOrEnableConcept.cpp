#include "ShockActionDisableOrEnableConcept.h"

#include "ShockPlayer.h"

UShockActionDisableOrEnableConcept::UShockActionDisableOrEnableConcept()
{
	ActionClassName = TEXT("ActionDisableOrEnableConcept");
}

void UShockActionDisableOrEnableConcept::Configure(FName InConceptName, bool bInEnable)
{
	ConceptName = InConceptName;
	bEnable = bInEnable;
}

bool UShockActionDisableOrEnableConcept::RequestToggle()
{
	if (ConceptName.IsNone())
	{
		return false;
	}
	LastConceptName = ConceptName;
	bLastEnable = bEnable;
	return true;
}

int32 UShockActionDisableOrEnableConcept::ApplyInWorld(UWorld* World)
{
	if (!RequestToggle())
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetConceptEnabled(ConceptName, bEnable);
	return 1;
}
