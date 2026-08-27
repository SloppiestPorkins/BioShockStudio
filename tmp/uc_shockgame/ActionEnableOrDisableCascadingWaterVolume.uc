class ActionEnableOrDisableCascadingWaterVolume extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name VolumeLabel;
var travel bool EnableVolume;

function Variable execute()
{
	local Actor TheVolume;
	local Class<CascadingWaterVolume> TheClass;

	super.execute();
	// End:0xCB
	foreach parentScript.__NFUN_304__(TheClass, TheVolume)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xCA
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA9
		/*@Error*/
		CascadingWaterVolume(TheVolume).EnableVolume();
		goto J0xCA;
		CascadingWaterVolume(TheVolume).DisableVolume(true);				
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
	// End:0x22
	if(EnableVolume)
	{
		S = "Enable";
		goto J0x35;
		S = "Disable";
	}
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, " cascading fluid volume "), string(VolumeLabel)), ".");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Enable or disable a CascadingWaterVolume"
	actionHelp="Enables or disables a CascadingWaterVolume"
	Category="Volumes"
}