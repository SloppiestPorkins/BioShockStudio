class DistanceTraveledSensorAction extends AI_SensorCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var private DistanceTraveledSensor DistanceTraveledSensor;
var private Vector LastLocation;
var private float CurrentDistance;

function setupSensors(AI_Resource resource)
{
	DistanceTraveledSensor = DistanceTraveledSensor(addSensorClass(Class'ShockAI.DistanceTraveledSensor'));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Cleanup()
{
	super(ActionBase).Cleanup();
	DistanceTraveledSensor = none;
	return;
	@NULL
	CommanderAction
}

function bool HasTravelerReachedDistanceToNotify()
{
	// End:0x58
	if(DistanceTraveledSensor.bCalculateUsing2dDistance)
	{
		__NFUN_184__(CurrentDistance, __NFUN_228__(__NFUN_216__(DistanceTraveledSensor.Traveler.Location, LastLocation)));
		goto J0x93;
		__NFUN_184__(CurrentDistance, __NFUN_225__(__NFUN_216__(DistanceTraveledSensor.Traveler.Location, LastLocation)));
	}
	log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " HasTravelerReachedDistanceToNotify - CurrentDistance: "), string(CurrentDistance)), " DistanceTraveledNotification: "), string(DistanceTraveledSensor.DistanceTraveledNotification)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x166
	/*@Error*/
	return true;
	LastLocation = DistanceTraveledSensor.Traveler.Location;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	assert(__NFUN_119__(m_Pawn, none));
	assert(__NFUN_119__(DistanceTraveledSensor, none));
	LastLocation = DistanceTraveledSensor.Traveler.Location;
	// End:0x86
	if(__NFUN_130__(__NFUN_151__(DistanceTraveledSensor.queryUsage(), 0), __NFUN_129__(HasTravelerReachedDistanceToNotify())))
	{
		yield();
		// [Loop Continue]
		goto J0x4B;
		// End:0xBA
		if(__NFUN_151__(DistanceTraveledSensor.queryUsage(), 0))
		{
			DistanceTraveledSensor.NotifyTravelerReachedDistance();
		}
		Pause();
		goto 'Begin';
		stop;		
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}
