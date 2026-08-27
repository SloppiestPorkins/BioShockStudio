class TeleportGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) private Actor TeleportAnchor;
var(Parameters) private Vector TeleportLocation;
var(Parameters) private bool TeleportRightNow;
var(Parameters) private bool UseOverriddenRotation;
var(Parameters) private Rotator OverriddenRotation;
var(Parameters) private bool SkipTimeInEther;

function Construct(AI_Resource R, Actor inTeleportAnchor, optional bool inTeleportRightNow, optional bool inUseOverriddenRotation, optional Rotator inOverriddenRotation, optional bool inSkipTimeInEther)
{
	construct_AI_Resource(R);
	assert(__NFUN_119__(inTeleportAnchor, none));
	TeleportAnchor = inTeleportAnchor;
	TeleportRightNow = inTeleportRightNow;
	UseOverriddenRotation = inUseOverriddenRotation;
	OverriddenRotation = inOverriddenRotation;
	SkipTimeInEther = inSkipTimeInEther;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function Construct(AI_Resource R, Vector inTeleportLocation, optional bool inTeleportRightNow, optional bool inUseOverriddenRotation, optional Rotator inOverriddenRotation, optional bool inSkipTimeInEther)
{
	construct_AI_Resource(R);
	TeleportLocation = inTeleportLocation;
	TeleportRightNow = inTeleportRightNow;
	UseOverriddenRotation = inUseOverriddenRotation;
	OverriddenRotation = inOverriddenRotation;
	SkipTimeInEther = inSkipTimeInEther;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	bTryOnlyOnce=true
	Priority=76
}