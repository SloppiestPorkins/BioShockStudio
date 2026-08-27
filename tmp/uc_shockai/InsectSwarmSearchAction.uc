class InsectSwarmSearchAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Rotator StartingRotation;
var private Vector Destination;
var private float ArrivalRadius;
var private MoveToGoal CurrentMoveToGoal;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	Destination = m_Pawn.Location;
	InitiateMovement();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	// End:0x29
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		super(AI_CharacterAction).Cleanup();
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function InitiateMovement()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location, true);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetUpdatedDestination__Delegate = GetUpdatedDestination;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnMoveEnded;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	outDestinationLocation = Destination;
	return;
	@NULL
	CommanderAction
}

function OnMoveEnded()
{
	FindNewDestination();
	return;
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	DesiredRotation = StartingRotation;
	return true;
	return;
	@NULL
	CommanderAction
}

function FindNewDestination(optional bool MoveForward)
{
	local NavigationPoint NavPoint, NewNavPoint;
	local array<ReachSpec> Supported;
	local Vector PotentialDestination;

	log('AI_Bioweapon', 4, __NFUN_112__("Searching for new destination from ", string(Destination)));
	// End:0x19D
	if(MoveForward)
	{
		PotentialDestination = __NFUN_215__(m_Pawn.Location, __NFUN_212__(Vector(m_Pawn.Rotation), InsectSwarm(m_Pawn).InitialMovementDistance));
		// End:0xF4
		if(m_Pawn.__NFUN_548__(PotentialDestination, m_Pawn.Location))
		{
			Destination = PotentialDestination;
			return;
			goto J0x19D;
			PotentialDestination = __NFUN_215__(m_Pawn.Location, __NFUN_212__(Vector(m_Pawn.Rotation), __NFUN_171__(InsectSwarm(m_Pawn).InitialMovementDistance, 0.5000000)));
		}
		// End:0x19D
		if(m_Pawn.__NFUN_548__(PotentialDestination, m_Pawn.Location))
		{
			Destination = PotentialDestination;
			return;
			NavPoint = m_Pawn.GetAnchor();
			NavPoint.GetReachSpecsThatSupport(m_Pawn, Supported);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x275
			/*@Error*/
			NewNavPoint = Supported[__NFUN_167__(Supported.Length)].End;
			Destination = NewNavPoint.Location;
			log('AI_Bioweapon', 4, __NFUN_112__("New destination = ", string(Destination)));
		}
	}
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsAtDestination()
{
	local Vector ZeroZ;

	ZeroZ = __NFUN_216__(m_Pawn.Location, Destination);
	ZeroZ.Z = 0.0000000;
	return __NFUN_176__(__NFUN_225__(ZeroZ), ArrivalRadius);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Bioweapon', 4, __NFUN_112__(string(Name), " Running of InsectSwarmSearchAction"));
	FindNewDestination(__NFUN_119__(InsectSwarm(m_Pawn).SwarmPlayerOwner, none));
	// End:0x88
	if(__NFUN_129__(IsAtDestination()))
	{
		__NFUN_256__(0.2000000);
		// [Loop Continue]
		goto J0x6E;
		yield();
		goto 'Search';
	}
	stop;			
	@NULL
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	ArrivalRadius=50.0000000
	satisfiesGoal=Class'ShockAI.InsectSwarmSearchGoal'
	bExclusiveAction=true
}