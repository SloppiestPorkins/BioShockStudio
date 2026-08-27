class JumpToCeilingGoal extends BioshockCharacterGoal
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

const kCollisionRadiiMultiplierToFitOnCeiling = 2.0;

var(Parameters) private Vector StartLocation;
var config float MaximumCeilingHeight;
var config float MaximumCeilingNormal;
var config float MaximumCeilingZVariance;

function Construct(AI_Resource R, int inPriority, Vector inStartLocation)
{
	construct_AI_Resource(R);
	Priority = inPriority;
	StartLocation = inStartLocation;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function bool CanJumpToCeiling(ShockPawn tester, Vector TestStartLocation)
{
	//native.tester;
	//native.TestStartLocation;	
	@NULL
	@NULL
}

defaultproperties
{
	MaximumCeilingHeight=1500.0000000
	MaximumCeilingNormal=0.9850000
	MaximumCeilingZVariance=16.0000000
	bTryOnlyOnce=true
}