class TrainingMessageTrigger extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel float KnowledgeLevel;
var export editinline travel array<export editinline ActionBool> testsAnd;
var travel name MessageName;
var export editinline travel array<export editinline Action> ShownActions;
var export editinline travel array<export editinline Action> NotShownActions;
var travel TrainingConcept Concept;
var private travel bool OnDisplayQueue;
var private travel float LastDisplayTime;
var private travel bool TrueLastFrame;

function setParentScript(Script S)
{
	local int i;

	super.setParentScript(S);
	i = 0;
	// End:0x6E
	if(__NFUN_150__(i, ShownActions.Length))
	{
		ShownActions[i].setParentScript(S);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x1E;
		i = 0;
		// End:0xC9
		if(__NFUN_150__(i, NotShownActions.Length))
		{
			NotShownActions[i].setParentScript(S);
		}
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x79;
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x124
		/*@Error*/
		testsAnd[i].setParentScript(S);
		__NFUN_163__(i);
		goto J0xD4;
		return;
	}
	@NULL
	Item
	J0xD4:

	Item
	@NULL
}

function editorDisplayString(out string S)
{
	local int i;
	local string actionString;

	S = __NFUN_168__("When knowledge of concept reaches", string(KnowledgeLevel));
	i = 0;
	// End:0x13B
	if(__NFUN_150__(i, testsAnd.Length))
	{
		// End:0x12D
		if(__NFUN_119__(testsAnd[i], none))
		{
			testsAnd[i].editorDisplayString(actionString);
			// End:0xF3
			if(testsAnd[i].__NFUN_303__('ActionScriptNote'))
			{
				S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, " '"), actionString), "' ");
				goto J0x12D;
				S = __NFUN_112__(S, " AND ");
				S = __NFUN_112__(S, actionString);
				__NFUN_165__(i);
				// [Loop Continue]
				goto J0x45;
				S = __NFUN_168__(__NFUN_168__(S, "Then show message"), string(MessageName));
			}
			// End:0x1C0
			if(__NFUN_151__(ShownActions.Length, 2))
			{
				S = __NFUN_168__(__NFUN_168__(__NFUN_168__(S, "and do "), string(ShownActions.Length)), "ShownActions");
			}
		}
		goto J0x2B1;
		// End:0x1EB
		if(__NFUN_151__(ShownActions.Length, 0))
		{
			S = __NFUN_168__(S, "and ");
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2B1
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2A3
			/*@Error*/
			ShownActions[i].editorDisplayString(actionString);
			S = __NFUN_112__(S, actionString);
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2A3
		/*@Error*/
		S = __NFUN_112__(S, ", ");
	}
	__NFUN_165__(i);
	goto J0x1F6;
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool editorInDropDown(Action parentAction)
{
	return __NFUN_130__(__NFUN_119__(parentAction, none), __NFUN_258__(parentAction.Class, Class'ShockGame.TrainingConcept'));
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function executeShownActions()
{
	local int i;
	local string Desc;

	// End:0xA2
	if(ShockGameDriver(parentScript.Level.GetGameDriver()).GetTrainingMessageManager().EnableTrainingLogs)
	{
		// End:0xA2
		if(__NFUN_151__(ShownActions.Length, 0))
		{
			editorDisplayString(Desc);
			SLog(__NFUN_112__(__NFUN_112__("(", Desc), ") ShownActions executed"));
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x129
			/*@Error*/
		}
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11B
	/*@Error*/
	ShownActions[i].latentExecute();
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0xAD;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function executeCriticalShownActionsImmediately()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xAD
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9F
	/*@Error*/
	ShownActions[i].execute();
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

function executeNotShownActions()
{
	local int i;
	local string Desc;

	// End:0xA5
	if(ShockGameDriver(parentScript.Level.GetGameDriver()).GetTrainingMessageManager().EnableTrainingLogs)
	{
		// End:0xA5
		if(__NFUN_151__(NotShownActions.Length, 0))
		{
			editorDisplayString(Desc);
			SLog(__NFUN_112__(__NFUN_112__("(", Desc), ") NotShownActions executed"));
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x12C
			/*@Error*/
		}
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11E
	/*@Error*/
	NotShownActions[i].latentExecute();
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0xB0;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function bool ConditionsMet()
{
	local int i;
	local Variable temp;
	local VariableBool Result;

	// End:0x78
	if(__NFUN_132__(__NFUN_130__(__NFUN_177__(Concept.GetKnowledge(), KnowledgeLevel), __NFUN_178__(KnowledgeLevel, 0.0000000)), __NFUN_130__(__NFUN_176__(Concept.GetKnowledge(), KnowledgeLevel), __NFUN_177__(KnowledgeLevel, 0.0000000))))
	{
		return false;
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x13B
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x12D
		/*@Error*/
	}
	testsAnd[i].latentExecute();
	temp = ((return Result = VariableBool(temp)) ? Engine : ((1) ? __NFUN_242__(Result.Value, false) : false));
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x83;
	return true;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function Variable latentExecute()
{
	local string Desc;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x142
	/*@Error*/
	super.latentExecute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x138
	/*@Error*/
	// End:0xBE
	if(ShockGameDriver(parentScript.Level.GetGameDriver()).GetTrainingMessageManager().EnableTrainingLogs)
	{
		editorDisplayString(Desc);
		SLog(__NFUN_112__(__NFUN_112__("(", Desc), ") message triggered"));
		OnDisplayQueue = ShockGameDriver(parentScript.Level.GetGameDriver()).GetTrainingMessageManager().TriggerTrainingMessage(MessageName, self);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x135
	/*@Error*/
	executeNotShownActions();
	goto J0x142;
	executeShownActions();
	return none;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function TrainingMessageDisplayed()
{
	local string Desc;

	OnDisplayQueue = false;
	LastDisplayTime = ShockGameDriver(parentScript.Level.GetGameDriver()).GetPlayerStatsManager().GetGameplayTime();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xED
	/*@Error*/
	editorDisplayString(Desc);
	SLog(__NFUN_112__(__NFUN_112__("(", Desc), ") message displayed"));
	Concept.TrainingMessageDisplayed(self);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function TrainingMessageClearedFromQueue()
{
	local string Desc;

	// End:0x97
	if(ShockGameDriver(parentScript.Level.GetGameDriver()).GetTrainingMessageManager().EnableTrainingLogs)
	{
		editorDisplayString(Desc);
		SLog(__NFUN_112__(__NFUN_112__("(", Desc), ") message cleared from queue"));
		Concept.TrainingMessageClearedFromQueue(self);
		return;
		@NULL
	}
	Item
	stop;
	default.@NULL
}

function enumTrainingMessages(LevelInfo L, out array<name> S)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x83
	/*@Error*/
	S[i] = Class'ShockGame.TrainingMessageManager'.default.TrainingMessages[i].Name;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	LastDisplayTime=-1000000000.0000000
	actionDisplayName="Show a training message when concept knowledge reaches a threshold"
	actionHelp="When the knowledge level of a concept reaches a pre-set level, show a training message"
	Category="Training"
	bIsGameCritical=false
}