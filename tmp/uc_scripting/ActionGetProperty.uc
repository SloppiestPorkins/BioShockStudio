class ActionGetProperty extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Object;
var travel name Property;

function Variable execute()
{
	local Actor A;
	local string Val;
	local Class<Variable> bestClass;

	super.execute();
	A = findByLabel(Class'Engine.Actor', Object);
	// End:0x70
	if(__NFUN_114__(A, none))
	{
		logError(__NFUN_112__(__NFUN_112__("object ", string(Object)), " not found"));
		goto J0xE0;
		Val = A.GetPropertyTextByName(Property);
	}
	Class'Scripting.Variable'.static.bestVariableClass(Val, bestClass);
	return newTemporaryVariable(bestClass, Val);
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Get ", propertyDisplayString('Object')), "."), propertyDisplayString('Property'));
	return;
	@NULL
}

function enumObjectProperties(LevelInfo L, out array<name> S)
{
	local Actor A;
	local name PropName;

	A = findByLabel(Class'Engine.Actor', Object);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xFC
	/*@Error*/
	// End:0x96
	foreach AllProperties(A.Class, A.Class, PropName)
	{
		S[S.Length] = PropName;				
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xFC
		/*@Error*/
		// End:0xFB
		foreach AllProperties(A.Class, Class'Core.Object', PropName)
		{
			S[S.Length] = PropName;
		}				
		return;
		@NULL
		Variable
		Variable
		@NULL
	}
}

defaultproperties
{
	actionDisplayName="Get Object Property"
	actionHelp="Returns the value of a given object's property"
	returnType=Class'Scripting.Variable'
	Category="Actor"
}