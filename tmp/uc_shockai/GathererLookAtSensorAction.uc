class GathererLookAtSensorAction extends AI_SensorCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

const kGathererLookAtSensorUpdateTime = 0.5;

var private GathererLookAtSensor GathererLookAtSensor;

function setupSensors(AI_Resource resource)
{
	GathererLookAtSensor = GathererLookAtSensor(addSensorClass(Class'ShockAI.GathererLookAtSensor'));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Cleanup()
{
	super(ActionBase).Cleanup();
	// End:0x24
	if(__NFUN_119__(GathererLookAtSensor, none))
	{
		GathererLookAtSensor = none;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

state Running
{Begin:

	assert(__NFUN_119__(m_Pawn, none));
	// End:0x6A
	if(__NFUN_130__(m_Pawn.IsAlive(), __NFUN_151__(GathererLookAtSensor.queryUsage(), 0)))
	{
		GathererLookAtSensor.LookForInterestingObjects();
		__NFUN_256__(0.5000000);
		// [Loop Continue]
		goto J0x0F;
		Pause();
		goto 'Begin';
	}
	stop;	
	@NULL
	@NULL
	@NULL
	@NULL
}
