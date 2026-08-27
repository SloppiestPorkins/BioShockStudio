class ActionLoop extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var export editinline travel array<export editinline Action> loopActions;
var private int CurrentIndex;

function OnScriptExit()
{
	// End:0x30
	if(__NFUN_153__(CurrentIndex, 0))
	{
		loopActions[CurrentIndex].OnScriptExit();
		return;
		@NULL
		Variable
	}
	Variable
}

function setParentScript(Script S)
{
	local int i;

	super.setParentScript(S);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6E
	/*@Error*/
	loopActions[i].setParentScript(S);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x1E;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function Variable latentExecute()
{
	resolveParameters();
	parentScript.enterLoop();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9A
	/*@Error*/
	J0x21:

	CurrentIndex = 0;
	// End:0x97
	if(__NFUN_150__(CurrentIndex, loopActions.Length))
	{
		// End:0x86
		if(parentScript.keepLooping())
		{
			loopActions[CurrentIndex].latentExecute();
			goto J0x89;
			goto J0x9A;
			__NFUN_163__(CurrentIndex);
			// [Loop Continue]
			goto J0x30;
			// [Loop Continue]
			goto J0x21;
			CurrentIndex = -1;
			return none;
		}
		return;
		J0x89:

		@NULL
		MessageTriggerVolume
		Variable
	}
	@NULL
}

function Variable execute()
{
	local int numTimesAlreadyLooped;
	local bool encounteredPotentialInfiniteLoopDuringLevelTransition;

	super.execute();
	parentScript.enterLoop();
	// End:0x3F
	if(__NFUN_154__(CurrentIndex, -1))
	{
		CurrentIndex = 0;
		// End:0x13E
		if(__NFUN_130__(true, __NFUN_129__(encounteredPotentialInfiniteLoopDuringLevelTransition)))
		{
		}
		// End:0xDF
		if(__NFUN_150__(CurrentIndex, loopActions.Length))
		{
			// End:0xCE
			if(parentScript.keepLooping())
			{
				// End:0xCB
				if(loopActions[CurrentIndex].bIsGameCritical)
				{
					loopActions[CurrentIndex].execute();
					goto J0xD1;
					goto J0x284;
					__NFUN_163__(CurrentIndex);
					// [Loop Continue]
					goto J0x54;
					CurrentIndex = 0;
					__NFUN_163__(numTimesAlreadyLooped);
					encounteredPotentialInfiniteLoopDuringLevelTransition = __NFUN_130__(__NFUN_130__(parentScript.bExecuteCriticalActionsImmediately, bIsGameCritical), __NFUN_153__(numTimesAlreadyLooped, 1000));
				}
			}
		}
		// [Loop Continue]
		goto J0x3F;
		AssertWithDescription(__NFUN_129__(encounteredPotentialInfiniteLoopDuringLevelTransition), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("DESIGNER SCRIPT BUG: Encountered potential infinite loop when processing ", string(Name)), " in Script "), string(parentScript)), " with Label "), string(parentScript.Label)), "; exiting after 1000 iterations. Designers should make sure loops are stopped before transitions or the loop actions are bGameCritical = false"));
	}
	CurrentIndex = -1;
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Loop";
	return;
	@NULL
}

defaultproperties
{
	CurrentIndex=-1
	actionDisplayName="Loop Statement"
	actionHelp="Continually loop over loopActions until ActionExitLoop is executed."
	Category="Script"
}