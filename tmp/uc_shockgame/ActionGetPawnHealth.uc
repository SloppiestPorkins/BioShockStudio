class ActionGetPawnHealth extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name PawnLabel;

function Variable execute()
{
	local ShockPawn ThePawn;

	super.execute();
	log('Scripting', 4, __NFUN_112__("ActionGetPawnHealth. PawnLabel=", string(PawnLabel)));
	ThePawn = ShockPawn(findByLabel(Class'ShockGame.ShockPawn', PawnLabel));
	AssertWithDescription(__NFUN_119__(ThePawn, none), __NFUN_112__("ActionGetPawnHealth was called with a label for a non-existent pawn. PawnLabel=", string(PawnLabel)));
	return newTemporaryVariable(Class'Scripting.VariableFloat', string(ThePawn.GetHealth()));
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Get the health of a pawn.";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Get the health of a pawn."
	actionHelp="Gets the health of a pawn."
	returnType=Class'Scripting.VariableFloat'
	Category="Pawn"
}