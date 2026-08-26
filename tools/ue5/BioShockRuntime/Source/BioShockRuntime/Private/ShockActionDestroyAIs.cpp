#include "ShockActionDestroyAIs.h"

UShockActionDestroyAIs::UShockActionDestroyAIs()
{
	ActionClassName = TEXT("ActionDestroyAIs");
}

void UShockActionDestroyAIs::Configure(FName InBaseClass, bool bInOnlyLowDetail)
{
	BaseClassName = InBaseClass;
	bOnlyLowDetailAIs = bInOnlyLowDetail;
}

void UShockActionDestroyAIs::SetLabelExceptions(const TArray<FName>& InExceptions)
{
	LabelExceptions = InExceptions;
}

bool UShockActionDestroyAIs::RequestDestroy()
{
	if (BaseClassName.IsNone())
	{
		return false;
	}
	LastBaseClassName = BaseClassName;
	return true;
}
