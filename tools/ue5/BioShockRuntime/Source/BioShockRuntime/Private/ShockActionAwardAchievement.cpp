#include "ShockActionAwardAchievement.h"

UShockActionAwardAchievement::UShockActionAwardAchievement()
{
	ActionClassName = TEXT("ActionAwardAchievement");
}

void UShockActionAwardAchievement::Configure(FName InAchievement)
{
	Achievement = InAchievement;
}

bool UShockActionAwardAchievement::RequestAward()
{
	if (Achievement.IsNone())
	{
		return false;
	}
	LastAchievement = Achievement;
	return true;
}
