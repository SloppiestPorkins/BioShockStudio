class AnimNotify_BeginGather extends AnimNotify_Scripted
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	assert(Owner.__NFUN_303__('Gatherer'));
	Gatherer(Owner).NotifyBeganGathering();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}
