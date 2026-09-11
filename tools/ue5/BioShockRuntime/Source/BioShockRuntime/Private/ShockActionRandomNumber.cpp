#include "ShockActionRandomNumber.h"

UShockActionRandomNumber::UShockActionRandomNumber()
{
	ActionClassName = TEXT("ActionRandomNumber");
}

void UShockActionRandomNumber::Configure(float InMinimum, float InMaximum)
{
	Minimum = InMinimum;
	Maximum = InMaximum;
}

bool UShockActionRandomNumber::ApplyInWorld(const FShockActionContext& Ctx)
{
	(void)Ctx;
	ClearReturnValue();
	const float Result = FMath::FRandRange(Minimum, Maximum);
	SetReturnValueText(LexToString(Result), TEXT("VariableFloat"));
	return true;
}
