class ActionModifyLocomotionKeyword extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel name keyword;
var travel int KeywordPriority;
var travel bool bAddKeyword;

function OutputAnimationKeywordsToBox(LevelInfo Level, out array<name> S)
{
	//native.Level;
	//native.S;	
	@NULL
	@NULL
}

function Variable execute()
{
	local ShockAI Iter;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB1
	/*@Error*/
	// End:0xB0
	foreach parentScript.allActorLabel(Class'ShockAI.ShockAI', Iter, AILabel)
	{
		// End:0x8F
		if(bAddKeyword)
		{
			Iter.AddLocomotionKeyword(keyword, KeywordPriority);
			goto J0xAF;
			Iter.RemoveLocomotionKeyword(keyword);						
			return none;
			return;
			@NULL
			CommanderAction
			CommanderAction
		}
		@NULL
	}
}

function editorDisplayString(out string S)
{
	// End:0xFD
	if(__NFUN_255__(AILabel, 'None'))
	{
		// End:0xA0
		if(bAddKeyword)
		{
			S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("AI with label ", string(AILabel)), " will have a keyword "), string(keyword)), " added or set to the value "), string(KeywordPriority));
			goto J0xFA;
			S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("AI with label ", string(AILabel)), " will have a keyword "), string(keyword)), " removed.");
		}
		goto J0x11C;
		S = "AILabel is not set!";
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

defaultproperties
{
	KeywordPriority=1
	bAddKeyword=true
	actionDisplayName="Set an AI's locomotion keyword"
	actionHelp="Set an AI's locomotion keyword"
	Category="AI"
}