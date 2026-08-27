class InvestigateGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var private Vector InvestigateLocation;
var private Vector InvestigateDirection;
var private name InvestigateSoundCategory;
var private float InvestigateTime;
//var delegate<GetInvestigateLocation> __GetInvestigateLocation__Delegate;

function Vector GetInvestigateLocation()
{
	return InvestigateLocation;
	return;
	@NULL
}

function Vector GetInvestigateDirection()
{
	return InvestigateDirection;
	return;
	@NULL
}

function name GetInvestigateSoundCategory()
{
	return InvestigateSoundCategory;
	return;
	@NULL
}

function float GetInvestigateTime()
{
	return InvestigateTime;
	return;
	@NULL
}

function UpdateInvestigationLocation(Vector NewInvestigateLocation, Vector NewInvestigateDirection, optional name inSoundCategory)
{
	InvestigateLocation = NewInvestigateLocation;
	InvestigateDirection = __NFUN_226__(NewInvestigateDirection);
	InvestigateSoundCategory = inSoundCategory;
	InvestigateTime = resource.Pawn().Level.TimeSeconds;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA5
	/*@Error*/
	InvestigateAction(achievingAction).NotifyInvestigateLocationUpdated();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Construct(AI_Resource R, Vector inInvestigateLocation, Vector inInvestigateDirection, optional name inSoundCategory)
{
	construct_AI_Resource(R);
	InvestigateLocation = inInvestigateLocation;
	InvestigateDirection = __NFUN_226__(inInvestigateDirection);
	InvestigateSoundCategory = inSoundCategory;
	InvestigateTime = R.Pawn().Level.TimeSeconds;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	bTryOnlyOnce=true
	Priority=70
}