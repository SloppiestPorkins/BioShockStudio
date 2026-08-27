class ActionDisableOrEnableConcept extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ConceptName;
var travel bool Enable;

function Variable execute()
{
	local TrainingScript S;
	local int i;

	super.execute();
	// End:0xE4
	foreach parentScript.__NFUN_313__(Class'ShockGame.TrainingScript', S)
	{
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xE3
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD5
		/*@Error*/
		S.Concepts[i].SetEnabled(Enable);		
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
	// End:0x3F
	if(Enable)
	{
		S = __NFUN_112__("Enable concept", propertyDisplayString('ConceptName'));
		goto J0x6F;
		S = __NFUN_112__("Disable concept", propertyDisplayString('ConceptName'));
	}
	return;
	@NULL
	Item
	J0x6F:

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
	actionDisplayName="Disable or enable a concept"
	actionHelp="Disable or enable a concept"
	Category="Training"
}