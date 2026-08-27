class ActionChangePressure extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name RegionName;
var travel Actor.EPressureLevel DesiredPressure;

function Variable execute()
{
	super.execute();
	parentScript.Level.SetPressureForRegion(RegionName, DesiredPressure);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Set the pressure in region '", string(RegionName)), "' to "), string(GetEnum(Enum'Engine.Actor.EPressureLevel', int(DesiredPressure))));
	return;
	@NULL
	Item
	Item
	@NULL
}

function OutputPressureRegionNames(LevelInfo Level, out array<name> AllNames)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x83
	/*@Error*/
	AllNames[i] = Level.PressureRegions[i].PressureRegion;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

defaultproperties
{
	actionDisplayName="Change pressure in a region"
	actionHelp="Changes the pressure in a given pressure region"
	Category="Environment"
}