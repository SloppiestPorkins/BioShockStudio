class ActionToggleSecurityCameraSpotlight extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name CameraLabel;
var travel bool SpotlightOn;

function Variable execute()
{
	local SecurityCamera FoundCamera;

	super.execute();
	// End:0x61
	foreach parentScript.dynamicActorLabel(Class'ShockAI.SecurityCamera', FoundCamera, CameraLabel)
	{
		FoundCamera.SetSpotlightState(SpotlightOn);				
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

function editorDisplayString(out string S)
{
	// End:0x47
	if(SpotlightOn)
	{
		S = __NFUN_112__(__NFUN_112__("Turn the spotlight on ", string(CameraLabel)), " on.");
		goto J0x7F;
		S = __NFUN_112__(__NFUN_112__("Turn the spotlight on ", string(CameraLabel)), " off.");
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Set the spotlight state of a security camera."
	actionHelp="Set the spotlight of a security camera to on or off."
	Category="Security"
}