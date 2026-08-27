class AlertSensorAction extends AI_SensorCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

const kAlertSensorUpdateTime = 0.5;

var private AlertSensor AlertSensor;

function setupSensors(AI_Resource resource)
{
	AlertSensor = AlertSensor(addSensorClass(Class'ShockAI.AlertSensor'));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Cleanup()
{
	super(ActionBase).Cleanup();
	// End:0x24
	if(__NFUN_119__(AlertSensor, none))
	{
		AlertSensor = none;
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
	if(__NFUN_130__(m_Pawn.IsAlive(), __NFUN_151__(AlertSensor.queryUsage(), 0)))
	{
		AlertSensor.TestForThreat();
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
