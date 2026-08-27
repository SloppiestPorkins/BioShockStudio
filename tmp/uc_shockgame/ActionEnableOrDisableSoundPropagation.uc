class ActionEnableOrDisableSoundPropagation extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool Enable;

function Variable execute()
{
	super.execute();
	// End:0x31
	if(Enable)
	{
		parentScript.EnableSoundPropagation();
		goto J0x48;
		parentScript.DisableSoundPropagation();
	}
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x22
	if(Enable)
	{
		S = "Enable";
		goto J0x35;
		S = "Disable";
	}
	S = __NFUN_112__(S, " sound propagation");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Enable or disable sound propagation"
	actionHelp="Enables or disables sound propagation"
	Category="AudioVisual"
}