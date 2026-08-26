#include "ShockActionControlPlant.h"

UShockActionControlPlant::UShockActionControlPlant()
{
	ActionClassName = TEXT("ActionControlPlant");
}

void UShockActionControlPlant::Configure(float InDuration, bool bInRevive)
{
	Duration = InDuration;
	bRevive = bInRevive;
}

bool UShockActionControlPlant::RequestControl()
{
	LastDuration = Duration;
	return true;
}
