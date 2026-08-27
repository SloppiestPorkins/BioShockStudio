class CharacterMoveToGoal extends BioshockCharacterGoal
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) private Actor DestinationActor;
var(Parameters) private bool bShouldNeverSucceed;
var(Parameters) private bool bShouldBeAggressive;
var(Parameters) private bool bShouldRun;
var private Rotator DesiredRotation;
var private bool bRotateToFaceDestinationRotation;
var private Actor DesiredFocus;
var private bool bRotateWhileMoving;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, int inBehaviorPriority, Actor inDestination, bool inShouldNeverSucceed, bool inShouldBeAggressive, bool inShouldRun, Rotator inDesiredRotation, bool inRotateToFaceDestinationRotation, Actor inDesiredFocus, bool inRotateWhileMoving)
{
	construct_AI_Resource(R);
	Priority = inBehaviorPriority;
	AssertWithDescription(__NFUN_119__(inDestination, none), __NFUN_112__(__NFUN_112__("MoveToGoal was passed a Destination that is None! (AI: ", string(R.Pawn().Name)), ")"));
	DestinationActor = inDestination;
	bShouldNeverSucceed = inShouldNeverSucceed;
	bShouldBeAggressive = inShouldBeAggressive;
	bShouldRun = inShouldRun;
	DesiredRotation = inDesiredRotation;
	bRotateToFaceDestinationRotation = inRotateToFaceDestinationRotation;
	DesiredFocus = inDesiredFocus;
	bRotateWhileMoving = inRotateWhileMoving;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function MoveToGoal CurrentMoveToGoal()
{
	// End:0x14
	if(__NFUN_114__(achievingAction, none))
	{
		return none;
		goto J0x34;
		return CharacterMoveToAction(achievingAction).CurrentMoveToGoal;
	}
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator NewDesiredRotation)
{
	local ShockAI AI;

	AI = ShockAI(resource.Pawn());
	assert(__NFUN_119__(AI, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x139
	/*@Error*/
	// End:0xD8
	if(bRotateToFaceDestinationRotation)
	{
		NewDesiredRotation = DestinationActor.Rotation;
		goto J0x137;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x124
		/*@Error*/
		NewDesiredRotation = Rotator(__NFUN_216__(DesiredFocus.Location, AI.Location));
		goto J0x137;
		NewDesiredRotation = DesiredRotation;
	}
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	bTryOnlyOnce=true
	Priority=90
}