class ActionGetConceptKnowledge extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ConceptName;

function Variable execute()
{
	local TrainingScript S;
	local VariableFloat returnVar;
	local int i;

	super.execute();
	// End:0x11F
	foreach parentScript.__NFUN_313__(Class'ShockGame.TrainingScript', S)
	{
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x11E
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x110
		/*@Error*/
		returnVar = VariableFloat(newTemporaryVariable(Class'Scripting.VariableFloat'));
		returnVar.Value = S.Concepts[i].GetKnowledge();		
		return returnVar;
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
	S = __NFUN_112__("Knowledge level of ", propertyDisplayString('ConceptName'));
	return;
	@NULL
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
	actionDisplayName="Knowledge level of a concept"
	actionHelp="Knowledge level of a concept"
	returnType=Class'Scripting.Variable'
	Category="Training"
}