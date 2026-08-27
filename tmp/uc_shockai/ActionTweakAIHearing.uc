class ActionTweakAIHearing extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel Class<ShockAI> AIClass;
var travel bool bTurnHearingOn;

function DisplayAITypes(LevelInfo Level, out array< Class<ShockAI> > S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	SpawningManager(Level.SpawningManager).DisplayAllAITypes(Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function string DisplayAITypeName(Class<ShockAI> AIClass)
{
	// End:0x2B
	if(__NFUN_119__(AIClass, none))
	{
		return string(AIClass.Name);
		goto J0x3B;
		return "Class Not Set";
	}
	return;
	@NULL
	CommanderAction
	J0x3B:

	CommanderAction
}

function TweakAIHearing(ShockAI Target)
{
	assert(__NFUN_119__(Target, none));
	Target.SetHearingState(bTurnHearingOn);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function Variable execute()
{
	local int i;
	local ShockAI Target;

	super.execute();
	// End:0x8A
	if(__NFUN_255__(AILabel, 'None'))
	{
		// End:0x86
		foreach parentScript.Level.dynamicActorLabel(Class'ShockAI.ShockAI', Target, AILabel)
		{
			// End:0x85
			if(__NFUN_119__(Target, none))
			{
				TweakAIHearing(Target);								
				goto J0x1AD;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x170
				/*@Error*/
				i = 0;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x16D
				/*@Error*/
			}
		}
	}
	Target = ShockAI(parentScript.Level.PawnList[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x15F
	/*@Error*/
	TweakAIHearing(Target);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xA4;
	goto J0x1AD;
	log('AI', 2, __NFUN_112__("No AILabel or AIClass set for ", string(Name)));
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Turn hearing ";
	// End:0x43
	if(bTurnHearingOn)
	{
		S = __NFUN_112__(S, "on ");
		goto J0x5E;
		S = __NFUN_112__(S, "off ");
	}
	// End:0xB4
	if(__NFUN_255__(AILabel, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__(S, "for AIs with the label: "), string(AILabel));
		goto J0xED;
		S = __NFUN_112__(__NFUN_112__(S, "for any AI of class: "), string(AIClass));
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	AIClass=Class'ShockAI.ShockAI'
	actionDisplayName="Tweak AI Hearing"
	actionHelp="Turn off or on the hearing of an AI"
	Category="AI"
}