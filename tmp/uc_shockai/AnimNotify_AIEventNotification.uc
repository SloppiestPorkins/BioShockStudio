class AnimNotify_AIEventNotification extends AnimNotify_Scripted
	editinlinenew
	collapsecategories
	hidecategories(Object);

var export editinline AIEventNotification Event;

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	Event.SourceActor = Owner;
	Event.SetLocation(Owner.Location);
	Owner.Level.SpawningManager.PostAIEventNotification(Event);
	Event.SourceActor = none;
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}
