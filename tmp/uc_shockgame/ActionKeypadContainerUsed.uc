class ActionKeypadContainerUsed extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name KeypadContainerLabel;
var travel bool Success;

function Variable execute()
{
	local KeypadContainer TheKeypadContainer;

	super.execute();
	log('Doors', 4, __NFUN_112__("ActionKeypadContainerUsed. KeypadContainerLabel=", string(KeypadContainerLabel)));
	TheKeypadContainer = KeypadContainer(findByLabel(Class'ShockGame.KeypadContainer', KeypadContainerLabel));
	AssertWithDescription(__NFUN_119__(TheKeypadContainer, none), __NFUN_112__("ActionKeypadContainerUsed was called with a label for a non-existent KeypadContainer. KeypadContainerLabel=", string(KeypadContainerLabel)));
	TheKeypadContainer.KeypadUsed(Success);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Tell KeypadContainer whether keycode was successfully entered or not.";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Tell KeypadContainer whether keycode was successfully entered or not."
	actionHelp="Tells KeypadContainer whether keycode was successfully entered or not."
	Category="Container"
}