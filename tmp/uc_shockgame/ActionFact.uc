class ActionFact extends Action
	abstract
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var /*0x00000000-0x00100000*/ travel name Slot_1;
var travel string Slot_2;
var travel string Slot_3;
var transient VariableFloat returnVar;
var array<int> FactIndices;

// Export UActionFact::execGetFactDatabase(FFrame&, void* const)
native function FactDatabase GetFactDatabase();

function MatchPattern(out array<int> Indices)
{
	//native.Indices;	
	@NULL
}

function ConvertToFactPattern(out FactPattern Pattern)
{
	Pattern.Slot_1 = Slot_1;
	Pattern.Slot_2 = Slot_2;
	Pattern.Slot_3 = Slot_3;
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function Variable execute()
{
	super.execute();
	// End:0x51
	if(__NFUN_114__(returnVar, none))
	{
		returnVar = Class'Scripting.VariableFloat'.static.Allocate(self,,, 134217728).;
		Construct_Void();
		return returnVar;
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function GetFactDisplayString(out string S)
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
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__("(", propertyDisplayString('Slot_1')), S), ")");
	}
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

defaultproperties
{
	Category="Facts"
}