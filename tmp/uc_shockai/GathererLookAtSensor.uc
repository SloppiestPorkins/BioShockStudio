class GathererLookAtSensor extends AI_Sensor
	native
	config(AI);

const HEADTRACKING_PAWNBIAS = 1000;
const HEADTRACKING_PLAYERBIAS = 2000;

var private Gatherer GathererTester;
var private config float MaxDistanceToNoticeInterestingObject;
var private config float MinDistanceToProtectorToNoticeInterestingObject;
var private config float MaxDistanceToHeadTrack;
var private config float MinDistanceToHeadTrack;

function setParameters(Gatherer inGathererTester)
{
	assert(Class'Engine.Pawn'.static.checkAlive(inGathererTester));
	GathererTester = inGathererTester;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x67
	/*@Error*/
	sensorAction.runAction();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UGathererLookAtSensor::execLookForInterestingObjects(FFrame&, void* const)
native function LookForInterestingObjects();

defaultproperties
{
	MaxDistanceToNoticeInterestingObject=750.0000000
	MinDistanceToProtectorToNoticeInterestingObject=100.0000000
	MaxDistanceToHeadTrack=2000.0000000
	MinDistanceToHeadTrack=200.0000000
	bNotifyOnValueChange=true
}