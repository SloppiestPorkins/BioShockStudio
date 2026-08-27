class ActionDestroyActor extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Target;

function Variable execute()
{
	local Actor A;
	local Pawn Pawn;

	super.execute();
	// End:0xE1
	foreach parentScript.dynamicActorLabel(Class'Engine.Actor', A, Target)
	{
		Pawn = Pawn(A);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD0
		/*@Error*/
		A.Level.Game.NotifyKilled(Pawn.Controller, Pawn.Controller, Pawn);
		A.__NFUN_279__();				
		return none;
		return;
		@NULL
		Variable
		Variable
		@NULL
	}
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Destroy Actor ", propertyDisplayString('Target'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Destroy Actor"
	actionHelp="Removes the target Actor from the game"
	Category="Actor"
}