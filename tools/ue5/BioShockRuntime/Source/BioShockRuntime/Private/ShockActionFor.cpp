#include "ShockActionFor.h"

UShockActionFor::UShockActionFor()
{
	ActionClassName = TEXT("ActionFor");
	CounterName = TEXT("forCounter");
	CurrentIndex = -1;
}

void UShockActionFor::Configure(FName InCounter, float InBegin, float InEnd, int32 InIndex)
{
	CounterName = InCounter;
	BeginValue = InBegin;
	EndValue = InEnd;
	CurrentIndex = InIndex;
}

bool UShockActionFor::RequestEnterFor()
{
	if (CounterName.IsNone())
	{
		return false;
	}
	bEnteredFor = true;
	return true;
}
