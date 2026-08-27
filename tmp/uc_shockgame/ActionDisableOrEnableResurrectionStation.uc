class ActionDisableOrEnableResurrectionStation extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name StationLabel;
var travel bool Enable;

function Variable execute()
{
	local BaseResurrectionStation TheStation;

	super.execute();
	log('Machines', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("ActionDisableOrEnableResurrectionStation. Enable=", string(Enable)), ", label = "), string(StationLabel)));
	// End:0xEA
	foreach parentScript.dynamicActorLabel(Class'ShockGame.BaseResurrectionStation', TheStation, StationLabel)
	{
		// End:0xD2
		if(Enable)
		{
			TheStation.EnableStation();
			goto J0xE9;
			TheStation.DisableStation();						
			return none;
			return;
			@NULL
			Item
			Item
		}
		@NULL
	}
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
	// End:0x91
	if(__NFUN_255__(StationLabel, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__(S, " resurrection station with label "), string(StationLabel));
		S = __NFUN_112__(S, ".");
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Enable or Disable a Resurrection Station."
	actionHelp="Enables or disables one or more resurrection stations."
	Category="Machines"
}