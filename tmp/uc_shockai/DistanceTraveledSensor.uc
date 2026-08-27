class DistanceTraveledSensor extends AI_Sensor;

var Actor Traveler;
var float DistanceTraveledNotification;
var bool bCalculateUsing2dDistance;

function setParameters(Actor inTraveler, float inDistanceTraveledNotification, bool inCalculateUsing2dDistance)
{
	assert(__NFUN_119__(inTraveler, none));
	assert(__NFUN_177__(inDistanceTraveledNotification, 0.0000000));
	Traveler = inTraveler;
	DistanceTraveledNotification = inDistanceTraveledNotification;
	bCalculateUsing2dDistance = inCalculateUsing2dDistance;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8E
	/*@Error*/
	sensorAction.runAction();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyTravelerReachedDistance()
{
	setObjectValue(Traveler);
	return;
	@NULL
}
