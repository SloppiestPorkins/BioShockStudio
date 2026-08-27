class ActionPostMovementGoal extends TyrionScriptAction
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Target;
var travel name DestinationLabel;
var travel Rotator DesiredRotation;
var travel bool bShouldRun;
var travel bool bShouldBeAggressive;
var travel bool bRotateToFaceDestinationRotation;
var travel bool bShouldNeverSucceed;
var travel string goalName;
var travel int Priority;
var travel name DesiredFocusLabel;
var travel bool bRotateWhileMoving;
var Actor Destination;
var Actor DesiredFocus;

function Variable latentExecute()
{
	local ShockAI Iter;
	local Gatherer Gatherer;
	local AI_Goal newGoal;

	execute();
	Destination = findByLabel(Class'Engine.Actor', DestinationLabel);
	AssertWithDescription(__NFUN_119__(Destination, none), __NFUN_112__("ActionPostMovementGoal was called with a label for a non-existent destination. DestinationLabel=", string(DestinationLabel)));
	// End:0xF2
	if(__NFUN_255__(DesiredFocusLabel, 'None'))
	{
		DesiredFocus = findByLabel(Class'Engine.Actor', DesiredFocusLabel);
		// End:0x2E7
		foreach parentScript.dynamicActorLabel(Class'ShockAI.ShockAI', Iter, Target)
		{
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2E6
			/*@Error*/
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x0C6! */
		Gatherer = Gatherer(Iter);
		// End:0x211
		if(__NFUN_130__(__NFUN_119__(Gatherer, none), Destination.__NFUN_303__('GathererVent')))
		{
			Gatherer.SetCurrentVent(GathererVent(Destination));
			newGoal = Class'ShockAI.ReturnToVentGoal'.static.Allocate(self).;
			construct_AI_ResourceBoolBool(Iter.CharacterAI, false, bShouldRun);
			goto J0x2AE;
			newGoal = Class'ShockAI.CharacterMoveToGoal'.static.Allocate(self).;
			construct_AI_ResourceIntActorBoolBoolBoolRotatorBoolActorBool(Iter.CharacterAI, Priority, Destination, bShouldNeverSucceed, bShouldBeAggressive, bShouldRun, DesiredRotation, bRotateToFaceDestinationRotation, DesiredFocus, bRotateWhileMoving);
			newGoal.goalName = goalName;
			newGoal.postGoal(none);
		}				
		return none;
		return;
		@NULL
		EcologyAI
		CommanderAction
		@NULL
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x099! */
}

function editorDisplayString(out string S)
{
	S = __NFUN_168__(__NFUN_168__(__NFUN_168__("Add movement goal named", goalName), "to"), propertyDisplayString('Target'));
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	goalName="MovementGoal"
	Priority=50
	actionDisplayName="Post Movement Goal"
	actionHelp="Adds a movement goal to an AI"
	Category="AI"
}