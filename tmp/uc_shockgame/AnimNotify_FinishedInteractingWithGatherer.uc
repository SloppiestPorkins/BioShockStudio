class AnimNotify_FinishedInteractingWithGatherer extends AnimNotify_Scripted
	editinlinenew
	collapsecategories
	hidecategories(Object);

var bool bSaving;

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	Hands(Owner).OnFinishedInteractingWithGatherer(bSaving);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}
