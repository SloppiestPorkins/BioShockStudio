class AnimNotify_SetHandsVisible extends AnimNotify_Scripted
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var bool bHide;

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	local Hands theHands;

	theHands = ShockPlayer(Owner.Level.GetLocalPlayerController().Pawn).GetHands();
	theHands.SetHidden(bHide);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}
