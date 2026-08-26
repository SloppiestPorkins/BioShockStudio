#include "ShockActionSetAIRangedWeaponAccuracy.h"

UShockActionSetAIRangedWeaponAccuracy::UShockActionSetAIRangedWeaponAccuracy()
{
	ActionClassName = TEXT("ActionSetAIRangedWeaponAccuracy");
}

void UShockActionSetAIRangedWeaponAccuracy::Configure(
	FName InLabel,
	FVector2D InAccPlayer,
	FVector2D InTimePlayer,
	FVector2D InAccAI,
	FVector2D InTimeAI)
{
	RangedWeaponLabel = InLabel;
	AccuracyRangeVsPlayer = InAccPlayer;
	AccuracyChangeTimeRangeVsPlayer = InTimePlayer;
	AccuracyRangeVsAI = InAccAI;
	AccuracyChangeTimeRangeVsAI = InTimeAI;
}

bool UShockActionSetAIRangedWeaponAccuracy::RequestSet()
{
	if (RangedWeaponLabel.IsNone())
	{
		return false;
	}
	LastRangedWeaponLabel = RangedWeaponLabel;
	return true;
}
