class ActionPostAINotificationEvent extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var export editinline travel AIEventNotification Event;
var travel name SourceLocationActorLabel;

function Variable execute()
{
	local Actor SourceActor;

	super.execute();
	SourceActor = findByLabel(Class'Engine.Actor', SourceLocationActorLabel);
	// End:0xE1
	if(__NFUN_119__(SourceActor, none))
	{
		Event.SetLocation(SourceActor.Location);
		Event.SourceActor = SourceActor;
		parentScript.Level.SpawningManager.PostAIEventNotification(Event);
		Event.SourceActor = none;
		goto J0x14F;
		log('Scripting', 3, __NFUN_112__(__NFUN_112__("Could not find source actor with name ", string(SourceLocationActorLabel)), ".  Not sending AI event notification."));
	}
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Post event at location of actor ", string(SourceLocationActorLabel)), ".");
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	actionDisplayName="Post an AI event notification."
	actionHelp="Post an AI event notification."
	Category="AI"
}