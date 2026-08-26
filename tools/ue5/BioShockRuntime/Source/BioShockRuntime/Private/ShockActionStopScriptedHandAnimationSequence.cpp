#include "ShockActionStopScriptedHandAnimationSequence.h"

UShockActionStopScriptedHandAnimationSequence::UShockActionStopScriptedHandAnimationSequence()
{
	ActionClassName = TEXT("ActionStopScriptedHandAnimationSequence");
}

bool UShockActionStopScriptedHandAnimationSequence::RequestStop()
{
	bStopped = true;
	return true;
}
