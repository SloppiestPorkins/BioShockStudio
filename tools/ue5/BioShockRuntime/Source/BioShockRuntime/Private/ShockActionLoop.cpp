#include "ShockActionLoop.h"

UShockActionLoop::UShockActionLoop()
{
	ActionClassName = TEXT("ActionLoop");
	CurrentIndex = -1;
}

void UShockActionLoop::Configure(int32 InCurrentIndex)
{
	CurrentIndex = InCurrentIndex;
}

bool UShockActionLoop::RequestEnterLoop()
{
	bEnteredLoop = true;
	if (CurrentIndex < 0)
	{
		CurrentIndex = 0;
	}
	return true;
}
