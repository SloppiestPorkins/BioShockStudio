class ActionIf extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var export editinline travel array<export editinline ActionBool> testsOr;
var export editinline travel array<export editinline Action> trueActions;
var export editinline travel array<export editinline Action> elseActions;
var private int CurrentOrIndex;
var private int CurrentTrueIndex;
var private int CurrentElseIndex;

function OnScriptExit()
{
	// End:0x30
	if(__NFUN_153__(CurrentOrIndex, 0))
	{
		testsOr[CurrentOrIndex].OnScriptExit();
		// End:0x60
		if(__NFUN_153__(CurrentTrueIndex, 0))
		{
			trueActions[CurrentTrueIndex].OnScriptExit();
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x90
		/*@Error*/
		elseActions[CurrentElseIndex].OnScriptExit();
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function setParentScript(Script S)
{
	local int i;

	super.setParentScript(S);
	i = 0;
	// End:0x6E
	if(__NFUN_150__(i, testsOr.Length))
	{
		testsOr[i].setParentScript(S);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x1E;
		i = 0;
		// End:0xC9
		if(__NFUN_150__(i, trueActions.Length))
		{
			trueActions[i].setParentScript(S);
		}
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x79;
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x124
		/*@Error*/
		elseActions[i].setParentScript(S);
		__NFUN_163__(i);
		goto J0xD4;
		return;
	}
	@NULL
	Variable
	J0xD4:

	Variable
	@NULL
}

function bool latentTestOrActions()
{
	local bool passedOrTests;
	local Variable temp;
	local VariableBool Result;

	CurrentOrIndex = 0;
	passedOrTests = false;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC0
	/*@Error*/
	testsOr[CurrentOrIndex].latentExecute();
	temp = ((return Result = VariableBool(temp)) ? Engine : __NFUN_116__(goto J0x162A, Result.Value));
	passedOrTests = true;
	goto J0xC0;
	__NFUN_163__(CurrentOrIndex);
	// [Loop Continue]
	goto J0x17;
	CurrentOrIndex = -1;
	return passedOrTests;
	return;
	@NULL
	MessageTriggerVolume
	ActionBool
	@NULL
}

function bool criticalTestOrActions()
{
	local bool passedOrTests;
	local Variable temp;
	local VariableBool Result;

	// End:0x1E
	if(__NFUN_154__(CurrentOrIndex, -1))
	{
		CurrentOrIndex = 0;
		passedOrTests = false;
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF5
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE7
	/*@Error*/
	temp = testsOr[CurrentOrIndex].execute();
	Result = VariableBool(temp);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE7
	/*@Error*/
	passedOrTests = true;
	goto J0xF5;
	__NFUN_163__(CurrentOrIndex);
	// [Loop Continue]
	goto J0x2A;
	CurrentOrIndex = -1;
	return passedOrTests;
	return;
	@NULL
	Variable
	ActionBool
	@NULL
}

function latentExecuteTrueActions()
{
	CurrentTrueIndex = 0;
	// End:0x6E
	if(__NFUN_130__(__NFUN_150__(CurrentTrueIndex, trueActions.Length), parentScript.continueExecution()))
	{
		trueActions[CurrentTrueIndex].latentExecute();
		__NFUN_163__(CurrentTrueIndex);
		// [Loop Continue]
		goto J0x0B;
		CurrentTrueIndex = -1;
		return;
		@NULL
		MessageTriggerVolume
		ActionBool
	}
	@NULL
}

function criticalExecuteTrueActions()
{
	// End:0x1E
	if(__NFUN_154__(CurrentTrueIndex, -1))
	{
		CurrentTrueIndex = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA5
		/*@Error*/
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x97
	/*@Error*/
	trueActions[CurrentTrueIndex].execute();
	__NFUN_163__(CurrentTrueIndex);
	// [Loop Continue]
	goto J0x1E;
	CurrentTrueIndex = -1;
	return;
	@NULL
	Variable
	ActionBool
	@NULL
}

function latentExecuteElseActions()
{
	CurrentElseIndex = 0;
	// End:0x6E
	if(__NFUN_130__(__NFUN_150__(CurrentElseIndex, elseActions.Length), parentScript.continueExecution()))
	{
		elseActions[CurrentElseIndex].latentExecute();
		__NFUN_163__(CurrentElseIndex);
		// [Loop Continue]
		goto J0x0B;
		CurrentElseIndex = -1;
		return;
		@NULL
		MessageTriggerVolume
		ActionBool
	}
	@NULL
}

function criticalExecuteElseActions()
{
	// End:0x1E
	if(__NFUN_154__(CurrentElseIndex, -1))
	{
		CurrentElseIndex = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA5
		/*@Error*/
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x97
	/*@Error*/
	elseActions[CurrentElseIndex].execute();
	__NFUN_163__(CurrentElseIndex);
	// [Loop Continue]
	goto J0x1E;
	CurrentElseIndex = -1;
	return;
	@NULL
	Variable
	ActionBool
	@NULL
}

function Variable latentExecute()
{
	local bool passedOrTests;

	CurrentOrIndex = -1;
	CurrentElseIndex = -1;
	CurrentTrueIndex = -1;
	resolveParameters();
	latentTestOrActions();
	// End:0x68
	passedOrTests = ((return if(passedOrTests)) ? default.@NULL : TriggerRadius)
	{
		goto J0x72;
		latentExecuteElseActions();
		return none;
		return;
		@NULL
	}
	MessageTriggerVolume
	Variable
	@NULL
}

function Variable execute()
{
	local bool passedOrTests;

	super.execute();
	// End:0x50
	if(__NFUN_155__(CurrentTrueIndex, -1))
	{
		assert(__NFUN_154__(CurrentElseIndex, -1));
		assert(__NFUN_154__(CurrentOrIndex, -1));
		criticalExecuteTrueActions();
		goto J0xBC;
		// End:0x83
		if(__NFUN_155__(CurrentElseIndex, -1))
		{
			assert(__NFUN_154__(CurrentOrIndex, -1));
		}
		criticalExecuteElseActions();
		goto J0xBC;
		passedOrTests = criticalTestOrActions();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xB2
		/*@Error*/
	}
	criticalExecuteTrueActions();
	goto J0xBC;
	criticalExecuteElseActions();
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	local int i;
	local string actionString;

	S = "If ";
	// End:0x40
	if(__NFUN_154__(testsOr.Length, 0))
	{
		S = __NFUN_112__(S, "nothing");
		goto J0x140;
		i = 0;
		// End:0x140
		if(__NFUN_150__(i, testsOr.Length))
		{
		}
		testsOr[i].editorDisplayString(actionString);
		// End:0xDE
		if(testsOr[i].__NFUN_303__('ActionScriptNote'))
		{
			S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, "'"), actionString), "'");
			goto J0x132;
			S = __NFUN_112__(S, actionString);
			// End:0x132
			if(__NFUN_150__(i, __NFUN_147__(testsOr.Length, 1)))
			{
				S = __NFUN_112__(S, " OR ");
				__NFUN_165__(i);
			}
			// [Loop Continue]
			goto J0x4B;
			S = __NFUN_112__(S, " Then ");
			// End:0x191
			if(__NFUN_154__(trueActions.Length, 0))
			{
				S = __NFUN_112__(S, "do nothing");
				goto J0x286;
				// End:0x1D9
				if(__NFUN_151__(trueActions.Length, 2))
				{
					S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, "do "), string(trueActions.Length)), " actions");
				}
			}
			goto J0x286;
			i = 0;
			// End:0x286
			if(__NFUN_150__(i, trueActions.Length))
			{
				trueActions[i].editorDisplayString(actionString);
				S = __NFUN_112__(S, actionString);
			}
			// End:0x278
			if(__NFUN_150__(i, __NFUN_147__(trueActions.Length, 1)))
			{
				S = __NFUN_112__(S, ", ");
				__NFUN_165__(i);
				goto J0x1E4;
				// End:0x298
				if(__NFUN_154__(elseActions.Length, 0))
				{
				}
				return;
				S = __NFUN_112__(S, ", Else ");
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x2FE
				/*@Error*/
				S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, "do "), string(elseActions.Length)), " actions");
				goto J0x3AB;
				i = 0;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x3AB
				/*@Error*/
				elseActions[i].editorDisplayString(actionString);
				S = __NFUN_112__(S, actionString);
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x39D
				/*@Error*/
			}
			S = __NFUN_112__(S, ", ");
		}
		__NFUN_165__(i);
	}
	goto J0x309;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	CurrentOrIndex=-1
	CurrentTrueIndex=-1
	CurrentElseIndex=-1
	actionDisplayName="If Statement"
	actionHelp="If one of the boolean statements in the 'testsOr' array is true, executes the Actions in 'trueActions', else executes the Actions in 'elseActions'."
	Category="Script"
}