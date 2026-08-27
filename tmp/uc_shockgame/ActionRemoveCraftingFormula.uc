class ActionRemoveCraftingFormula extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel Class<CraftingFormula> FormulaClass;

function Variable execute()
{
	super.execute();
	ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).RemoveCraftingFormula(FormulaClass);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Remove <", string(FormulaClass)), "> from the player's list of craftable formulae.");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Remove a crafting formula"
	actionHelp="Removes a crafting recipie from the player's list of crafting formulae."
	Category="Inventory"
}