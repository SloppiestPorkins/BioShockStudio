class ActionModifyStat extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name PawnLabel;
var travel name ModGroup;
var travel float BaseValue;

function Variable execute()
{
	local ShockPawn ThePawn;

	super.execute();
	ThePawn = ShockPawn(findByLabel(Class'ShockGame.ShockPawn', PawnLabel));
	return newTemporaryVariable(Class'Scripting.VariableFloat', string(ThePawn.ModifyStat(ModGroup, BaseValue)));
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Modifies the value '", string(BaseValue)), "' by "), string(PawnLabel)), "'s active mods in group '"), string(ModGroup)), "'.");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	PawnLabel="Player"
	actionDisplayName="Get a stat modification."
	actionHelp="Modifies a value by the specified pawn's active mods."
	returnType=Class'Scripting.Variable'
	Category="Mods"
}