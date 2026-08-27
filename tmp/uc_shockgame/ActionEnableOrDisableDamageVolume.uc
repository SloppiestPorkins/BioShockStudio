class ActionEnableOrDisableDamageVolume extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name VolumeLabel;
var travel bool EnableVolume;

function Variable execute()
{
	local ShockDamageVolume TheVolume;

	super.execute();
	// End:0x7E
	foreach parentScript.staticActorLabel(Class'ShockGame.ShockDamageVolume', TheVolume, VolumeLabel)
	{
		// End:0x66
		if(EnableVolume)
		{
			TheVolume.EnableVolume();
			goto J0x7D;
			TheVolume.DisableVolume();						
			return none;
			return;
			@NULL
			Item
		}
		Item
		@NULL
	}
}

function editorDisplayString(out string S)
{
	// End:0x22
	if(EnableVolume)
	{
		S = "Enable";
		goto J0x35;
		S = "Disable";
	}
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, " damage volume "), string(VolumeLabel)), ".");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Enable or disable a ShockDamageVolume"
	actionHelp="Enables or disables a ShockDamageVolume"
	Category="Volumes"
}