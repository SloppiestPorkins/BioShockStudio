class ActionMakeBotsAttack extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ControllerLabel;
var travel name AttackeeLabel;

function Variable execute()
{
	local ShockPawn Attacker, Attackee;

	super.execute();
	Attackee = ShockPawn(parentScript.findByLabel(Class'ShockGame.ShockPawn', AttackeeLabel));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xAD
	/*@Error*/
	// End:0xAC
	foreach parentScript.dynamicActorLabel(Class'ShockGame.ShockPawn', Attacker, ControllerLabel)
	{
		Attacker.AttackTargetWithBots(Attackee, true);				
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
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Make ", string(ControllerLabel)), "'s bots attack "), string(AttackeeLabel)), ".");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Makes a pawn's bots  attack another pawn."
	actionHelp="Makes a pawn's bots attack something."
	Category="Actor"
}