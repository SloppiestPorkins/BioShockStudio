class ActionGrenadierUseLiveGrenadeWeapon extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name GrenadierLabel;

function Variable execute()
{
	local Grenadier TargetGrenadier;

	super.execute();
	TargetGrenadier = Grenadier(findByLabel(Class'ShockAI.Grenadier', GrenadierLabel));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5F
	/*@Error*/
	TargetGrenadier.UseLiveGrenadeWeapon();
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x88
	if(__NFUN_255__(GrenadierLabel, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__("Tells a Grenadier with label ", string(GrenadierLabel)), " to use its live grenade (over the shoulder) weapon.");
		goto J0xAE;
		S = "GrenadierLabel is not set!";
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Tells a grenadier to use its live grenade attack"
	actionHelp="Tells a grenadier to use its live grenade attack"
	Category="AI"
}