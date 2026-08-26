#include "ShockActionStartScriptedHandAnimationSequence.h"

UShockActionStartScriptedHandAnimationSequence::UShockActionStartScriptedHandAnimationSequence()
{
	ActionClassName = TEXT("ActionStartScriptedHandAnimationSequence");
}

bool UShockActionStartScriptedHandAnimationSequence::RequestStart()
{
	bStarted = true;
	return true;
}
