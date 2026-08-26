#include "ShockActionTellAIToSendWeaponFireMessage.h"

UShockActionTellAIToSendWeaponFireMessage::UShockActionTellAIToSendWeaponFireMessage()
{
	ActionClassName = TEXT("ActionTellAIToSendWeaponFireMessage");
}

void UShockActionTellAIToSendWeaponFireMessage::Configure(FName InAI, FName InWeaponLabel, FName InWeaponClass)
{
	AILabel = InAI;
	WeaponLabel = InWeaponLabel;
	WeaponClass = InWeaponClass;
}

bool UShockActionTellAIToSendWeaponFireMessage::RequestTell()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}
