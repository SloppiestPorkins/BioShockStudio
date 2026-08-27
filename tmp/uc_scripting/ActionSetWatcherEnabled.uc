class ActionSetWatcherEnabled extends Action
	abstract
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name scriptName;
var travel name watcherName;
var private travel bool enabled;

function Variable execute()
{
	local Script S;

	super.execute();
	// End:0x85
	if(__NFUN_255__(scriptName, 'None'))
	{
		// End:0x81
		foreach parentScript.dynamicActorLabel(Class'Scripting.Script', S, scriptName)
		{
			S.setWatcherEnabled(watcherName, enabled);						
			goto J0xAF;
			parentScript.setWatcherEnabled(watcherName, enabled);
			return none;
			return;
			@NULL
		}
		Variable
	}
	Variable
	@NULL
}
