class ActionCalcDistance extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name actorOne;
var travel name actorTwo;
var /*0x00000000-0x00100000*/ transient Actor A;
var /*0x00000000-0x00100000*/ transient Actor B;

function Variable execute()
{
	local Variable Result;

	super.execute();
	// End:0x37
	if(__NFUN_114__(A, none))
	{
		A = findByLabel(none, actorOne);
		// End:0x64
		if(__NFUN_114__(B, none))
		{
			B = findByLabel(none, actorTwo);
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD3
		/*@Error*/
		Result = newTemporaryVariable(Class'Scripting.VariableFloat', string(__NFUN_225__(__NFUN_216__(A.Location, B.Location))));
	}
	return Result;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Distance between ", propertyDisplayString('actorOne')), " and "), propertyDisplayString('actorTwo'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Calculate Distance"
	actionHelp="Calculate the distance between two actors"
	returnType=Class'Scripting.Variable'
	Category="Actor"
}