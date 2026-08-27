class ActionSetPlayerFOV extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel float FOV;

function Variable execute()
{
	super.execute();
	// End:0xAA
	if(__NFUN_130__(__NFUN_242__(parentScript.Level.GetGameDriver().GetUserSettings().bHorizontalFOVLock, true), __NFUN_179__(FOV, float(1))))
	{
		ShockPlayerController(parentScript.Level.GetLocalPlayerController()).DesiredFOV = FOV;
		goto J0x11F;
		ShockPlayerController(parentScript.Level.GetLocalPlayerController()).DesiredFOV = ShockPlayerController(parentScript.Level.GetLocalPlayerController()).DefaultFOV;
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
	// End:0x45
	if(__NFUN_179__(FOV, float(1)))
	{
		S = __NFUN_112__(__NFUN_112__("Set player FOV to '", string(FOV)), "'");
		goto J0x6A;
		S = "Set player FOV to Default";
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Set player FOV."
	actionHelp="Set player FOV. To reset to default, set to 0."
	Category="Player"
}