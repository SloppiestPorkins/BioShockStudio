class ActionPostGatherGoal extends TyrionScriptAction
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name BootyLabel;
var travel name Target;
var travel string goalName;
var travel bool bShouldRun;

function Variable latentExecute()
{
	local Actor Booty;
	local Gatherer Gatherer;
	local AI_Goal newGoal;

	execute();
	Booty = findByLabel(Class'Engine.Actor', BootyLabel);
	AssertWithDescription(__NFUN_119__(Booty, none), __NFUN_112__("ActionPostGatherGoal was called with a label for non-existent booty. BootyLabel=", string(BootyLabel)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1A0
	/*@Error*/
	// End:0x19F
	foreach parentScript.dynamicActorLabel(Class'ShockAI.Gatherer', Gatherer, Target)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x19E
		/*@Error*/
		newGoal = Class'ShockAI.GatherResourceGoal'.static.Allocate(self).;
		construct_AI_ResourceActorBool(Gatherer.CharacterAI, Booty, bShouldRun);
		newGoal.goalName = goalName;
		newGoal.postGoal(none);				
		return none;
		return;
		@NULL
		EcologyAI
		CommanderAction
		@NULL
	}
}

function editorDisplayString(out string S)
{
	S = __NFUN_168__(__NFUN_168__(__NFUN_168__("Add gather goal named", goalName), "to the gatherer"), propertyDisplayString('Target'));
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	goalName="GatherGoal"
	actionDisplayName="Post Gather Goal"
	actionHelp="Adds a gather goal to a gatherer"
	Category="AI"
}