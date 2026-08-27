class ActionWaitForQuestLogToFinish extends ActionWaitForCriticalMessage
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var private travel Class<QuestLog> QuestLog;

function AllPlayableQuestLogClasses(LevelInfo Level, out array< Class<QuestLog> > S)
{
	local Class StupidCompilerBug;
	local Class<QuestLog> QuestLogSubclass;
	local Class BaseClass;

	BaseClass = Class'ShockGame.QuestLog';
	// End:0xBB
	foreach AllClasses(BaseClass, StupidCompilerBug)
	{
		QuestLogSubclass = Class<QuestLog>(StupidCompilerBug);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xBA
		/*@Error*/
		S[S.Length] = QuestLogSubclass;				
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

function string DisplayClassNameFunc(Class<QuestLog> theLog)
{
	local string displayString;

	// End:0x3D
	if(__NFUN_258__(theLog, Class'ShockGame.QuestLog'))
	{
		displayString = string(theLog.Name);
		goto J0x6C;
		displayString = "<INTERNAL ERROR, SHOW A PROGRAMMER>";
	}
	return displayString;
	return;
	@NULL
	Item
	Item
	@NULL
}

function GetEffectSpecCorrespondingToLogPlayedEventWithGivenTag(name LogPlayedEventTag, out SoundEffectSpecification Spec)
{
	//native.LogPlayedEventTag;
	//native.Spec;	
	@NULL
	@NULL
}

function Variable latentExecute()
{
	local Variable ret;
	local SoundEffectSpecification Spec;

	resolveParameters();
	AssertWithDescription(__NFUN_119__(QuestLog, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("No QuestLog specific for ", string(Name)), " in Script "), string(parentScript.Name)), ", action will not work"));
	// End:0x9C
	if(__NFUN_114__(QuestLog, none))
	{
		return none;
		GetEffectSpecCorrespondingToLogPlayedEventWithGivenTag(QuestLog.default.EffectTag, Spec);
	}
	EffectSpecToWaitFor = Spec.Name;
	super.latentExecute();
	ret = ((return return ret) ? @NULL : Item);
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Wait up to ", string(TimeoutSeconds)), " seconds for QuestLog "), string(QuestLog.Name)), " to finish playing");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Wait for QuestLog audio to finish"
	actionHelp="Wait for audio from a particular QuestLog to stop, with an optional timeout"
}