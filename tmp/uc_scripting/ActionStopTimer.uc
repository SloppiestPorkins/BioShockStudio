class ActionStopTimer extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name scriptLabel;

function Variable execute()
{
	local Script S;

	super.execute();
	// End:0x56
	foreach parentScript.dynamicActorLabel(Class'Scripting.Script', S, scriptLabel)
	{
		S.__NFUN_280__(0.0000000, false);				
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
	S = __NFUN_112__("Stop timer for ", propertyDisplayString('scriptLabel'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Stop Timer"
	actionHelp="Stops the timer for all scripts with the given label"
	Category="Script"
}