class ActionTestFact extends ActionBool
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var /*0x00000000-0x00100000*/ travel name Slot_1;
var travel string Slot_2;
var travel string Slot_3;

// Export UActionTestFact::execTestFact(FFrame&, void* const)
protected native function TestFact();

function Variable execute()
{
	super.execute();
	TestFact();
	return returnVar;
	return;
	@NULL
	Item
}

function editorDisplayString(out string S)
{
	local string SlotDesc;

	S = "";
	SlotDesc = propertyDisplayString('Slot_3');
	// End:0x51
	if(__NFUN_123__(SlotDesc, ""))
	{
		S = __NFUN_168__(",", SlotDesc);
		SlotDesc = propertyDisplayString('Slot_2');
	}
	// End:0xA1
	if(__NFUN_123__(SlotDesc, ""))
	{
		S = __NFUN_112__(__NFUN_168__(",", SlotDesc), S);
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Is fact (", propertyDisplayString('Slot_1')), S), ") true");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function enumFacts(LevelInfo Level, out array<name> S)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x73
	/*@Error*/
	S[S.Length] = Class'ShockGame.FactDatabase'.default.PredefinedFacts[i];
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
	actionDisplayName="Test if a Fact is true"
	actionHelp="Returns Fact evaluated as a boolean"
	Category="Facts"
}