class ActionModifyConceptKnowledge extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ConceptName;
var travel float Weight;

function Variable execute()
{
	local TrainingScript S;
	local int i;

	super.execute();
	// End:0xE3
	foreach parentScript.__NFUN_313__(Class'ShockGame.TrainingScript', S)
	{
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xE2
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD4
		/*@Error*/
		S.Concepts[i].ModifyKnowledge(Weight);		
		return none;
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x3A;				
		return none;
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

function editorDisplayString(out string S)
{
	S = __NFUN_168__(__NFUN_168__(__NFUN_112__("Modify knowledge level of ", propertyDisplayString('ConceptName')), "by"), string(Weight));
	return;
	@NULL
	Item
}

function enumConcepts(LevelInfo L, out array<name> n)
{
	local TrainingScript S;
	local int i;

	// End:0xA6
	foreach parentScript.__NFUN_313__(Class'ShockGame.TrainingScript', S)
	{
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA5
		/*@Error*/
		n[n.Length] = S.Concepts[i].ConceptName;
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x30;				
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

defaultproperties
{
	actionDisplayName="Modify knowledge level of a concept"
	actionHelp="Modify knowledge level of a concept"
	Category="Training"
}