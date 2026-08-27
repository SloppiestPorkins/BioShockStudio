class ActionChangeResistanceSet extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Target;
var travel name ResistanceSetName;

function Variable execute()
{
	local Actor TestActor;
	local ReactiveActor theReactiveActor;
	local ShockPawn theShockPawn;

	// End:0xFE
	foreach parentScript.dynamicActorLabel(Class'Engine.Actor', TestActor, Target)
	{
		theReactiveActor = ReactiveActor(TestActor);
		// End:0x99
		if(__NFUN_119__(theReactiveActor, none))
		{
			theReactiveActor.DamageResistanceSetName = ResistanceSetName;
			theReactiveActor.ChangeResistanceSet = true;
			theShockPawn = ShockPawn(TestActor);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xFD
			/*@Error*/
			theShockPawn.DamageResistanceSetName = ResistanceSetName;
			theShockPawn.ChangeResistanceSet = true;
		}				
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
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Change the Resistance set of '", string(Target)), "' to '"), string(ResistanceSetName)), "'.");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	ResistanceSetName="Default"
	actionDisplayName="Change Resistance Set"
	actionHelp="Change the Resistance set of a ReactiveActor or Pawn."
	Category="Actor"
}