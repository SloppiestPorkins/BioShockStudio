class ActionStopEffect extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var editconst travel name EffectEvent;
var travel name EffectTag;
var travel name ActorLabel;

function Variable execute()
{
	local Actor Actor;
	local string ConfiguratorEventName, LogMessage;

	super.execute();
	// End:0x239
	foreach parentScript.dynamicActorLabel(Class'Engine.Actor', Actor, ActorLabel)
	{
		Actor.UnTriggerEffectEvent(EffectEvent, EffectTag);
		ConfiguratorEventName = __NFUN_112__(string(Actor.Class.Name), string(EffectEvent));
		// End:0xE0
		if(__NFUN_255__(EffectTag, 'None'))
		{
			ConfiguratorEventName = __NFUN_112__(__NFUN_112__(ConfiguratorEventName, "_"), string(EffectTag));
			LogMessage = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " Stopped (unTriggered) effect event "), ConfiguratorEventName), ": "), " Event '"), propertyDisplayString('EffectEvent')), "'");
		}
		// End:0x1A7
		if(__NFUN_255__(EffectTag, 'None'))
		{
			LogMessage = __NFUN_112__(__NFUN_112__(__NFUN_112__(LogMessage, " with tag '"), propertyDisplayString('EffectTag')), "'");
			LogMessage = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(LogMessage, " on actor '"), string(Actor.Name)), "' (actor class is "), string(Actor.Class.Name)), ")");
		}
		SLog(LogMessage);				
		return none;
		return;
		@NULL
		Variable
		Variable
		@NULL
	}
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Stop effect event ", propertyDisplayString('EffectEvent'));
	// End:0x86
	if(__NFUN_255__(EffectTag, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, " with tag '"), propertyDisplayString('EffectTag')), "'");
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, " on actor labeled '"), propertyDisplayString('ActorLabel')), "'");
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	EffectEvent="ScriptTrigger"
	actionDisplayName="Stop Effect"
	actionHelp="Stops a playing an effect that was previously started via the Play Effect action"
	Category="AudioVisual"
}