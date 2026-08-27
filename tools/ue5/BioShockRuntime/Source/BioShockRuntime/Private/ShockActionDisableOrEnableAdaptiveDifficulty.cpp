#include "ShockActionDisableOrEnableAdaptiveDifficulty.h"

UShockActionDisableOrEnableAdaptiveDifficulty::UShockActionDisableOrEnableAdaptiveDifficulty()
{
	ActionClassName = TEXT("ActionDisableOrEnableAdaptiveDifficulty");
}

void UShockActionDisableOrEnableAdaptiveDifficulty::Configure(bool bInEnable)
{
	bEnable = bInEnable;
}

bool UShockActionDisableOrEnableAdaptiveDifficulty::RequestSet()
{
	bLastEnable = bEnable;
	return true;
}
