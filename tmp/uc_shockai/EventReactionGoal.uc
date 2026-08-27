class EventReactionGoal extends BioshockCharacterGoal
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var private AIEventNotification Event;

function Construct(AI_Resource R, AIEventNotification inEvent)
{
	construct_AI_Resource(R);
	Event = inEvent.Clone(R.Pawn().Level);
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function Actor GetEventSourceActor()
{
	return Event.SourceActor;
	return;
	@NULL
	CommanderAction
}

function Vector GetEventSourceLocation()
{
	return Event.Location;
	return;
	@NULL
	CommanderAction
}

function Vector GetSecondaryEventLocation()
{
	return Event.GetSecondaryLocation();
	return;
	@NULL
}

function AIEventNotification.EAIEventNotificationType GetEventNotificationType()
{
	return Event.NotificationType;
	return;
	@NULL
	CommanderAction
}

function float GetEventReactionChance()
{
	return Event.ReactionChance;
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	Priority=72
}