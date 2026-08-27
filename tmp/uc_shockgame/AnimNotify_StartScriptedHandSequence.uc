class AnimNotify_StartScriptedHandSequence extends AnimNotify_Scripted
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	local Hands theHands;

	theHands = ShockPlayer(Owner.Level.GetLocalPlayerController().Pawn).GetHands();
	theHands.StartScriptedHandAnimationSequence();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}
