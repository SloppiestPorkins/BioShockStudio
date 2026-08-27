class ActionSetAIPatrol extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AggressorLabel;
var travel name PatrolName;

function Variable execute()
{
	local Aggressor Iter;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x91
	/*@Error*/
	// End:0x90
	foreach parentScript.dynamicActorLabel(Class'ShockAI.Aggressor', Iter, AggressorLabel)
	{
		Iter.SetScriptedPatrol(PatrolName);				
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

function OutputPatrolsToBox(LevelInfo Level, out array<name> S)
{
	Class'ShockAI.SpawningManager'.static.OutputPatrolsToBox(Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Aggressor with label ", string(AggressorLabel)), " will be told to use patrol "), string(PatrolName));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

defaultproperties
{
	actionDisplayName="Set a Patrol on an Aggressor"
	actionHelp="Set a Patrol on an Aggressor"
	Category="AI"
}