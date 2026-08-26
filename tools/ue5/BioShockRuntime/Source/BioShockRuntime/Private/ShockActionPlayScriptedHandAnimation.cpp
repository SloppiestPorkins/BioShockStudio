#include "ShockActionPlayScriptedHandAnimation.h"

UShockActionPlayScriptedHandAnimation::UShockActionPlayScriptedHandAnimation()
{
	ActionClassName = TEXT("ActionPlayScriptedHandAnimation");
	AnimationEndBehavior = 4;
}

void UShockActionPlayScriptedHandAnimation::Configure(
	FName InHand,
	FName InAttachment,
	int32 InEndBehavior,
	float InEaseIn,
	bool bInWait)
{
	HandAnimation = InHand;
	AttachmentAnimation = InAttachment;
	AnimationEndBehavior = InEndBehavior;
	EaseIn = InEaseIn;
	bWaitForAnimationToFinish = bInWait;
}

bool UShockActionPlayScriptedHandAnimation::RequestPlay()
{
	if (HandAnimation.IsNone())
	{
		return false;
	}
	LastHandAnimation = HandAnimation;
	return true;
}
