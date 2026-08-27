class ActionWaitForCriticalMessageStart extends Action implements IInterestedInCriticalMessageEvents
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name EffectEventToWaitFor;
var travel float TimeoutSeconds;
var travel name ActorLabel;
var private travel float WakeTime;
var private travel bool AudioStarted;
var private transient CriticalMessageQueue CMQ;

function OnCriticalMessageStarted(name EffectEvent, name EffectSpecificationName, VolumeCategory.EVolumeCategory VolumeCategory)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x10C
	/*@Error*/
	SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), "Audio Spec='"), string(EffectSpecificationName)), "' from Event='"), string(EffectEvent)), "' Category='"), string(GetEnum(Enum'Engine.VolumeCategory.EVolumeCategory', int(VolumeCategory)))), "' started at time "), string(parentScript.Level.TimeSeconds)));
	AudioStarted = true;
	CMQ.RemoveCriticalMessageEventObserver(self);
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function OnCriticalMessageStopped(name EffectEvent, name EffectSpecificationName, VolumeCategory.EVolumeCategory VolumeCategory, bool PlayedToCompletion)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x10E
	/*@Error*/
	SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), "Audio Spec='"), string(EffectSpecificationName)), "' from Event='"), string(EffectEvent)), "' Category='"), string(GetEnum(Enum'Engine.VolumeCategory.EVolumeCategory', int(VolumeCategory)))), "' completed at time "), string(parentScript.Level.TimeSeconds)));
	AudioStarted = true;
	CMQ.RemoveCriticalMessageEventObserver(self);
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function PostCheckpointRestore()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x12B
	/*@Error*/
	CMQ = Class'IGSoundEffectsSubsystem.SoundEffectsSubsystem'.static.GetCriticalMessageQueue(parentScript);
	AssertWithDescription(__NFUN_119__(CMQ, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " in Script "), string(parentScript.Name)), "could not register with CriticalMessageQueue after checkpoint restore; this action may not work correctly."));
	CMQ.AddCriticalMessageEventObserver(self);
	return;
	@NULL
	Variable
	stop;
	default.@NULL
}

function Variable latentExecute()
{
	resolveParameters();
	AssertWithDescription(__NFUN_255__(EffectEventToWaitFor, 'None'), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("EffectEventToWaitFor not specified for ", string(Name)), " in Script "), string(parentScript.Name)), ", action will not work"));
	// End:0xBA
	if(__NFUN_254__(EffectEventToWaitFor, 'None'))
	{
		return none;
		SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " began waiting at time "), string(parentScript.Level.TimeSeconds)), " for audio event='"), string(EffectEventToWaitFor)), "' to finish, or will time out after "), string(TimeoutSeconds)), " seconds"));
	}
	WakeTime = __NFUN_174__(parentScript.Level.TimeSeconds, TimeoutSeconds);
	AudioStarted = false;
	CMQ = Class'IGSoundEffectsSubsystem.SoundEffectsSubsystem'.static.GetCriticalMessageQueue(parentScript);
	AssertWithDescription(__NFUN_119__(CMQ, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " in Script "), string(parentScript.Name)), "could not register with CriticalMessageQueue when starting; this action may not work correctly."));
	CMQ.AddCriticalMessageEventObserver(self);
	// End:0x311
	if(__NFUN_130__(__NFUN_130__(__NFUN_129__(AudioStarted), __NFUN_176__(parentScript.Level.TimeSeconds, WakeTime)), parentScript.continueExecution()))
	{
		__NFUN_256__(0.0000000);
		goto J0x2A8;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3DA
		/*@Error*/
		SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " Timed out at time "), string(parentScript.Level.TimeSeconds)), " after waiting "), string(TimeoutSeconds)), " seconds for audio Spec='"), string(EffectEventToWaitFor)), "' to complete"));
	}
	AudioStarted = true;
	CMQ.RemoveCriticalMessageEventObserver(self);
	WakeTime = 0.0000000;
	return none;
	return;
	@NULL
	MessageTriggerVolume
	Variable
	@NULL
}

function Variable execute()
{
	super.execute();
	return none;
	return;
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Wait up to ", string(TimeoutSeconds)), " seconds for audio '"), propertyDisplayString('EffectEventToWaitFor')), "' to start playing");
	return;
	@NULL
	Variable
}

defaultproperties
{
	TimeoutSeconds=60.0000000
	actionDisplayName="Wait for scripted vo to start."
	actionHelp="Wait for audio from a particular EffectSpecification to start, with an optional timeout"
	Category="AudioVisual"
}