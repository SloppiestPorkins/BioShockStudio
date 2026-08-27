class ActionExitScript extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name targetScript;

function Variable execute()
{
	local Script S;

	super.execute();
	// End:0x57
	foreach parentScript.dynamicActorLabel(Class'Scripting.Script', S, targetScript)
	{
		S.Exit();				
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
	S = __NFUN_112__("Exit script ", propertyDisplayString('targetScript'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Exit Script"
	actionHelp="Ends execution of a script"
	Category="Script"
}