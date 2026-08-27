class ActionSetMaterialSwitchIndex extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var /*0x00000000-0x00100000*/ travel MaterialSwitch Material;
var travel float Index;

function Variable execute()
{
	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x88
	/*@Error*/
	logError(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Index ", string(int(Index))), " out-of-bounds (0,"), string(Material.Materials.Length)), ")"));
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	local string MaterialName;

	// End:0x34
	if(__NFUN_119__(Material, none))
	{
		MaterialName = string(Material.Name);
		goto J0x44;
		MaterialName = "None";
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Set the current index of ", MaterialName), " to "), propertyDisplayString('Index'));
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	actionDisplayName="Set MaterialSwitch Index"
	actionHelp="Sets the given MaterialSwitch's index to the given index. Fails if the index is out of bounds"
	Category="AudioVisual"
}