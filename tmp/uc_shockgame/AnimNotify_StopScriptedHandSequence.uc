class AnimNotify_StopScriptedHandSequence extends AnimNotify_Scripted
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	local Hands theHands;

	theHands = ShockPlayer(Owner.Level.GetLocalPlayerController().Pawn).GetHands();
	theHands.StopScriptedHandAnimationSequence();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}
