class ActionPlayEffect extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var editconst travel name EffectEvent;
var travel name EffectTag;
var travel name ActorLabel;
var bool SlowAlsoTriggerOnStaticActors;
var bool LogTriggerInfo;

function executeInternal(Actor theActor)
{
	local string ConfiguratorEventName, LogMessage;

	theActor.TriggerEffectEvent(EffectEvent,,,,,,,, EffectTag);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x201
	/*@Error*/
	ConfiguratorEventName = __NFUN_112__(string(theActor.Class.Name), string(EffectEvent));
	// End:0xB5
	if(__NFUN_255__(EffectTag, 'None'))
	{
		ConfiguratorEventName = __NFUN_112__(__NFUN_112__(ConfiguratorEventName, "_"), string(EffectTag));
		LogMessage = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " triggered effect event "), ConfiguratorEventName), ": "), " Event '"), propertyDisplayString('EffectEvent')), "'");
	}
	// End:0x170
	if(__NFUN_255__(EffectTag, 'None'))
	{
		LogMessage = __NFUN_112__(__NFUN_112__(__NFUN_112__(LogMessage, " with tag '"), propertyDisplayString('EffectTag')), "'");
		LogMessage = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(LogMessage, " on actor '"), string(theActor.Name)), "' (actor class is "), string(theActor.Class.Name)), ")");
	}
	SLog(LogMessage);
	return;
	@NULL
	Variable
	ActionBool
	@NULL
}

function Variable execute()
{
	local Actor Actor;

	super.execute();
	// End:0xC8
	if(__NFUN_255__(ActorLabel, 'None'))
	{
		// End:0x7B
		if(SlowAlsoTriggerOnStaticActors)
		{
			// End:0x77
			foreach parentScript.allActorLabel(Class'Engine.Actor', Actor, ActorLabel)
			{
				executeInternal(Actor);								
				goto J0xC5;
				// End:0xC4
				foreach parentScript.allActorLabel(Class'Engine.Actor', Actor, ActorLabel)
				{
					executeInternal(Actor);
				}
			}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x022! */						
			goto J0x141;
			SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("WARNING: ", string(Name)), " in Script "), string(parentScript.Name)), " cannot execute because actorLabel is None"));
		}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x019! */
	}
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Trigger effect event ", propertyDisplayString('EffectEvent'));
	// End:0x89
	if(__NFUN_255__(EffectTag, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, " with tag '"), propertyDisplayString('EffectTag')), "'");
		S = __NFUN_112__(S, " on ");
	}
	// End:0xDE
	if(SlowAlsoTriggerOnStaticActors)
	{
		S = __NFUN_112__(S, " dynamic AND static");
		goto J0xFD;
		S = __NFUN_112__(S, " dynamic");
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, " actors labeled '"), propertyDisplayString('ActorLabel')), "'");
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
	actionDisplayName="Play Effect"
	actionHelp="Plays an effect"
	Category="AudioVisual"
	bIsGameCritical=false
}