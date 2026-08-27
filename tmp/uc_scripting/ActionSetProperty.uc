class ActionSetProperty extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Object;
var travel name Property;
var travel string NewValue;

function Variable execute()
{
	local Actor A;

	super.execute();
	// End:0x3D
	if(IsCensoredContent())
	{
		parentScript.Level.bSetCommandEnabled = true;
		// End:0x12A
		foreach parentScript.allActorLabel(Class'Engine.Actor', A, Object)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x029! */
		A.SetPropertyText(string(Property), NewValue);
		// End:0xE5
		if(__NFUN_254__(Property, 'bHidden'))
		{
			A.SetHidden(A.bHidden);
			goto J0x129;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x129
			/*@Error*/
			A.SetLabel(A.Label);						
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x15E
			/*@Error*/
			parentScript.Level.bSetCommandEnabled = false;
		}
		return none;
		return;
		@NULL
		Variable
		Variable
		@NULL
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x006! */
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Set ", propertyDisplayString('Object')), "."), propertyDisplayString('Property')), " = "), propertyDisplayString('NewValue'));
	return;
	@NULL
}

function enumObjectProperties(LevelInfo L, out array<name> S)
{
	local Actor A;
	local array< Class > classes;
	local Class commonBaseClass;
	local name PropName;

	// End:0x61
	foreach parentScript.allActorLabel(Class'Engine.Actor', A, Object)
	{
		classes[classes.Length] = A.Class;				
		commonBaseClass = CommonBase(classes);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD6
		/*@Error*/
		// End:0xD5
		foreach AllProperties(commonBaseClass, Class'Core.Object', PropName)
		{
		}
		S[S.Length] = PropName;				
		return;
		@NULL
		Variable
		Variable
		@NULL
	}
}

defaultproperties
{
	actionDisplayName="Set Object Property"
	actionHelp="Sets a new value for a given object's property"
	Category="Actor"
}