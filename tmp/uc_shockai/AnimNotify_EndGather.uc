class AnimNotify_EndGather extends AnimNotify_Scripted
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	assert(Owner.__NFUN_303__('Gatherer'));
	Gatherer(Owner).NotifyEndedGathering();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}
