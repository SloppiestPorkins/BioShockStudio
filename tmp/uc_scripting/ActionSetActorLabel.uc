class ActionSetActorLabel extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ActorLabel;
var travel name NewLabel;

function Variable execute()
{
	local Actor A;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x78
	/*@Error*/
	// End:0x77
	foreach parentScript.allActorLabel(Class'Engine.Actor', A, ActorLabel)
	{
		A.SetLabel(NewLabel);				
		return none;
		return;
		@NULL
		Variable
		Variable
		@NULL
	}
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Change label of ", propertyDisplayString('ActorLabel')), " to "), propertyDisplayString('NewLabel'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Change the label of an actor"
	actionHelp="Changes the label of an actor"
	Category="Actor"
}