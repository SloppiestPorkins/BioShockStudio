class ActionWaitUntilActorHasLanded extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name TargetLabel;

function Variable execute()
{
	super.execute();
	return none;
	return;
	@NULL
}

function Variable latentExecute()
{
	local Actor A;

	A = parentScript.findByLabel(Class'Engine.Actor', TargetLabel);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA4
	/*@Error*/
	A.__NFUN_3970__(4);
	A.Velocity = vect(0.0000000, 0.0000000, 0.0000000);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA4
	/*@Error*/
	__NFUN_256__(0.0000000);	
	return none;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Wait for actor '", string(TargetLabel)), "' to fall and land.");
	return;
	@NULL
	Item
}

defaultproperties
{
	TargetLabel="UNSPECIFIED"
	actionDisplayName="Wait for actor to fall and land"
	actionHelp="Blocks the script from executing until the specified actor has landed."
	Category="Actor"
	bIsGameCritical=false
}