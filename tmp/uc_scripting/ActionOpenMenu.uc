class ActionOpenMenu extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel string Menu;
var travel string param_1;
var travel string param_2;
var travel string param_3;

function Variable execute()
{
	local PlayerController PC;

	super.execute();
	PC = parentScript.Level.GetLocalPlayerController();
	// End:0x96
	if(__NFUN_119__(PC, none))
	{
		PC.Player.GUIController.OpenMenu(Menu, param_1, param_2);
		goto J0xC4;
		SLog("Couldn't get the player controller");
		return none;
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Open menu ", propertyDisplayString('Menu'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Open Menu"
	actionHelp="Opens a menu"
	Category="Other"
}