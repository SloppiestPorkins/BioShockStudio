class ActionDestroyAIs extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel Class<ShockAI> BaseClass;
var travel array<name> LabelExceptions;
var travel bool bOnlyLowDetailAIs;

function DisplayAbstractAITypes(LevelInfo Level, out array< Class<ShockAI> > S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	SpawningManager(Level.SpawningManager).DisplayAbstractAITypes(Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Variable latentExecute()
{
	local ShockAI Iter;
	local int i;

	execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x160
	/*@Error*/
	i = __NFUN_147__(parentScript.Level.PawnList.Length, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x160
	/*@Error*/
	Iter = ShockAI(parentScript.Level.PawnList[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x152
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x152
	/*@Error*/
	Iter.__NFUN_279__();
	__NFUN_164__(i);
	// [Loop Continue]
	goto J0x4A;
	return none;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function bool IsStunnedGatherer(ShockAI TestAI)
{
	local Gatherer TestGatherer;

	TestGatherer = Gatherer(TestAI);
	return __NFUN_130__(__NFUN_119__(TestGatherer, none), TestGatherer.IsStunned());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsOnExceptionList(name Label)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	// End:0x46
	if(__NFUN_254__(Label, LabelExceptions[i]))
	{
		return true;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x30
	if(__NFUN_114__(BaseClass, none))
	{
		S = "BaseClass not set!";
		goto J0xCE;
		S = __NFUN_112__("Destroy all AIs of type ", string(BaseClass));
	}
	// End:0xA2
	if(__NFUN_151__(LabelExceptions.Length, 0))
	{
		S = __NFUN_112__(S, ", with some exceptions.");
		goto J0xCE;
		S = __NFUN_112__(S, ", with no exceptions.");
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	bOnlyLowDetailAIs=true
	actionDisplayName="Destroy a number of AIs at the same time"
	actionHelp="Destroy a number of AIs at the same time"
	Category="AI"
}