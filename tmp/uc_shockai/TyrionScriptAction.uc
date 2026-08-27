class TyrionScriptAction extends Action
	abstract
	editinlinenew
	collapsecategories
	hidecategories(Object);

function enumTyrionTargets(LevelInfo Level, out array<name> S)
{
	local Actor A;

	// End:0xA9
	foreach Level.__NFUN_304__(Class'Engine.Actor', A)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA8
		/*@Error*/
		S[S.Length] = A.Label;				
		return;
		@NULL
		CommanderAction
		stop;
		default.@NULL
	}
}

function unPostGoal(Actor A, string goalName)
{
	local AI_Goal Goal;

	Goal = Class'VengeanceShared.AI_Goal'.static.findGoalByName(A, goalName);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x95
	/*@Error*/
	// End:0x7D
	if(__NFUN_114__(Goal.resource, none))
	{
		Goal.Priority = -1;
		goto J0x95;
		Goal.unPostGoal(none);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}
