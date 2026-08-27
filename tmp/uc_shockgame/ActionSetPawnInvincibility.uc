class ActionSetPawnInvincibility extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name PawnLabel;
var travel bool bInvincible;

function Variable execute()
{
	local ShockPawn Target;

	super.execute();
	Target = ShockPawn(parentScript.findByLabel(Class'ShockGame.ShockPawn', PawnLabel));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x76
	/*@Error*/
	Target.SetInvincible(bInvincible);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x56
	if(bInvincible)
	{
		S = __NFUN_112__(__NFUN_112__("Pawn with label ", string(PawnLabel)), " will be made invincible.");
		goto J0xA0;
		S = __NFUN_112__(__NFUN_112__("Pawn with label ", string(PawnLabel)), " will be made not invincible.");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	bInvincible=true
	actionDisplayName="Make a Pawn invincible"
	actionHelp="Sets whether a particular Pawn is invincible or not."
	Category="AI"
}