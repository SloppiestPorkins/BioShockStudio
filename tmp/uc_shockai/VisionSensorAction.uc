class VisionSensorAction extends AI_SensorCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var private VisionSensor VisionSensor;

function setupSensors(AI_Resource resource)
{
	VisionSensor = VisionSensor(addSensorClass(Class'ShockAI.VisionSensor'));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Cleanup()
{
	super(ActionBase).Cleanup();
	VisionSensor = none;
	return;
	@NULL
	CommanderAction
}

state Running
{Begin:

	assert(__NFUN_119__(m_Pawn, none));
	assert(__NFUN_119__(VisionSensor, none));
	VisionSensor.UpdateVision();
	Pause();
	goto 'Begin';
	stop;		
	@NULL
	@NULL
	@NULL
}
