class ActionSetMovableSpotlightState extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name SpotlightLabel;
var travel bool SpotlightOn;

function Variable execute()
{
	local MovableSpotlight Spotlight;

	super.execute();
	// End:0x61
	foreach parentScript.staticActorLabel(Class'ShockGame.MovableSpotlight', Spotlight, SpotlightLabel)
	{
		Spotlight.SetSpotlightState(SpotlightOn);				
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
	// End:0x48
	if(SpotlightOn)
	{
		S = __NFUN_112__(__NFUN_112__("Turns MovableSpotlight ", string(SpotlightLabel)), " on.");
		goto J0x81;
		S = __NFUN_112__(__NFUN_112__("Turns MovableSpotlight ", string(SpotlightLabel)), " off.");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Turn a spotlight on or off."
	actionHelp="Turns a movable spotlight on or off."
	Category="Lights"
}