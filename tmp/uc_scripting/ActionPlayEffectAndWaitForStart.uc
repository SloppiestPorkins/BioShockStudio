class ActionPlayEffectAndWaitForStart extends Action implements IEffectObserver
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name EffectEventToPlay;
var travel name EffectTag;
var travel float TimeoutSeconds;
var travel name ActorLabel;
var bool SlowAlsoTriggerOnStaticActors;
var bool LogTriggerInfo;
var private travel float WakeTime;
var private travel bool AudioStarted;
var private int InitializedAudioCounter;
var array<SoundInstance> StartedSoundInstances;

function executeInternal(Actor theActor)
{
	local string ConfiguratorEventName, LogMessage;
	local EffectEventInfo EventInfo;

	EventInfo.ReferenceTag = EffectTag;
	theActor.TriggerEffectEvent(EffectEventToPlay,,,,,,, self, EffectTag, EventInfo);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x22A
	/*@Error*/
	ConfiguratorEventName = __NFUN_112__(string(theActor.Class.Name), string(EffectEventToPlay));
	// End:0xDE
	if(__NFUN_255__(EffectTag, 'None'))
	{
		ConfiguratorEventName = __NFUN_112__(__NFUN_112__(ConfiguratorEventName, "_"), string(EffectTag));
		LogMessage = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " triggered effect event "), ConfiguratorEventName), ": "), " Event '"), propertyDisplayString('EffectEventToPlay')), "'");
	}
	// End:0x199
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

function OnEffectInitialized(Actor EffectInitialized)
{
	local SoundInstance Sound;

	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("ON EFFECT INITIALIZED! effect ", string(EffectInitialized)), " at time "), string(parentScript.Level.TimeSeconds)), ", InitializedAudioCounter: "), string(InitializedAudioCounter)));
	Sound = SoundInstance(EffectInitialized);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x137
	/*@Error*/
	Sound.AddNativeFlag(1024);
	__NFUN_165__(InitializedAudioCounter);
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function OnScreenEffectStarted(ReferenceCountedObject inStartedEffect)
{
	return;
}

function OnScreenEffectStopped(ReferenceCountedObject inStoppedEffect)
{
	return;
}

function OnEffectStarted(Actor EffectStarted)
{
	local SoundInstance SoundStarted;

	SoundStarted = SoundInstance(EffectStarted);
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__("ON EFFECT STARTED! effect ", string(EffectStarted)), ", InitializedAudioCounter: "), string(InitializedAudioCounter)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1AD
	/*@Error*/
	SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), "Audio Spec='"), string(SoundStarted.Schema)), "' from Event='"), string(EffectEventToPlay)), "' started at time "), string(parentScript.Level.TimeSeconds)));
	__NFUN_166__(InitializedAudioCounter);
	StartedSoundInstances[StartedSoundInstances.Length] = SoundStarted;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1C8
	/*@Error*/
	AudioStarted = true;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function OnEffectStopped(Actor EffectStopped, bool bCompleted)
{
	local SoundInstance SoundStopped;

	SoundStopped = SoundInstance(EffectStopped);
	log(,, "ON EFFECT STOPPED!");
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xFE
	/*@Error*/
	SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), "Audio Spec='"), string(SoundStopped.Schema)), "' from Event='"), string(EffectEventToPlay)), "' failed to play correctly at time "), string(parentScript.Level.TimeSeconds)));
	AudioStarted = true;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function Variable latentExecute()
{
	local Actor Actor;
	local int ct;

	resolveParameters();
	// End:0xC5
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
				}
				executeInternal(Actor);
			}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x026! */						
			AssertWithDescription(__NFUN_255__(EffectEventToPlay, 'None'), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("EffectEventToPlay not specified for ", string(Name)), " in Script "), string(parentScript.Name)), ", action will not work"));
		}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x01D! */
	}
	// End:0x172
	if(__NFUN_254__(EffectEventToPlay, 'None'))
	{
		return none;
		SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " began waiting at time "), string(parentScript.Level.TimeSeconds)), " for audio event='"), string(EffectEventToPlay)), "' to finish, or will time out after "), string(TimeoutSeconds)), " seconds"));
	}
	WakeTime = __NFUN_174__(parentScript.Level.TimeSeconds, TimeoutSeconds);
	AudioStarted = false;
	// End:0x2DA
	if(__NFUN_130__(__NFUN_130__(__NFUN_129__(AudioStarted), __NFUN_176__(parentScript.Level.TimeSeconds, WakeTime)), parentScript.continueExecution()))
	{
		__NFUN_256__(0.0000000);
		goto J0x271;
		// End:0x3A6
		if(__NFUN_129__(AudioStarted))
		{
			SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " Timed out at time "), string(parentScript.Level.TimeSeconds)), " after waiting "), string(TimeoutSeconds)), " seconds for audio Spec='"), string(EffectEventToPlay)), "' to complete"));
		}
		AudioStarted = true;
		goto J0x568;
		ct = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x4DD
		/*@Error*/
		SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), "Audio Spec='"), string(StartedSoundInstances[ct].Schema)), "' started at time "), string(parentScript.Level.TimeSeconds)));
		assert(__NFUN_119__(StartedSoundInstances[ct], none));
		assert(__NFUN_119__(StartedSoundInstances[ct].ActualSound, none));
		StartedSoundInstances[ct].ActualSound.UnPause(StartedSoundInstances[ct]);
	}
	__NFUN_163__(ct);
	// [Loop Continue]
	goto J0x3B1;
	SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " Leaving latent state at time "), string(parentScript.Level.TimeSeconds)), " audio Spec='"), string(EffectEventToPlay)), "' completed"));
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
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Wait up to ", string(TimeoutSeconds)), " seconds for audio '"), propertyDisplayString('EffectEventToPlay')), "' to start playing");
	return;
	@NULL
	Variable
}

defaultproperties
{
	TimeoutSeconds=60.0000000
	actionDisplayName="Play an audio effect event and wait for it to start playing."
	actionHelp="Play the audio effect event and wait for it to start, with an optional timeout"
	Category="AudioVisual"
}