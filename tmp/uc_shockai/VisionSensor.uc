class VisionSensor extends AI_Sensor implements IVisionNotification, IInterestedPawnDied
	native
	config(AI);

enum EVisionNotificationStatus
{
	kInvalidNotification,           // 0
	kTargetSeen,                    // 1
	kTargetLost,                    // 2
	kTargetSuspicious               // 3
};

struct native export atomic VisionInfo
{
	structcpptext
	{

		FVisionInfo()
			: CertaintyWeight(0.f), 
			  SuspiciousWeight(0.f),
			  bCurrentlyVisible(1), 
			  NumLOS(0), 
			  bNotifiedVisible(0), 
			  LastTimeSeen(0.f),
			  LastKnownLocation(0.f,0.f,0.f),
			  LastMovingDirection(0.f,0.f,0.f),
			  LocationWhenLostTarget(0.f,0.f,0.f)
		{
		}
	
	}

	var float CertaintyWeight;
	var float SuspiciousWeight;
	var int bCurrentlyVisible;
	var int NumLOS;
	var int bNotifiedVisible;
	var float LastTimeSeen;
	var Vector LastKnownLocation;
	var Vector LastMovingDirection;
	var Vector LocationWhenLostTarget;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var private ShockAI Viewer;
var private config Range IlluminationRange;
var private config Range LOSVisionRange;
var private config float MinIlluminationTimeMultiplier;
var private config float MidIlluminationTimeMultiplier;
var private config float MaxIlluminationTimeMultiplier;
var private config float MinLOSVisionTimeMultiplier;
var private config float MidLOSVisionTimeMultiplier;
var private config float MaxLOSVisionTimeMultiplier;
var private config float PlayerNotFacingMultiplier;
var private const noexport transient TMap_Padding VisionInfoMap;

function setParameters(ShockAI InViewer)
{
	assert(Class'Engine.Pawn'.static.checkAlive(InViewer));
	Viewer = InViewer;
	Viewer.RegisterVisionNotification(self);
	Viewer.Level.RegisterNotifyPawnDied(self);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA4
	/*@Error*/
	sensorAction.runAction();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super.Cleanup();
	ClearVisionInfoMap();
	Viewer.UnregisterVisionNotification(self);
	Viewer.Level.UnRegisterNotifyPawnDied(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UVisionSensor::execClearVisionInfoMap(FFrame&, void* const)
private native function ClearVisionInfoMap();

function OnOtherPawnDied(Pawn DeadPawn)
{
	//native.DeadPawn;	
	@NULL
}

// Export UVisionSensor::execUpdateVision(FFrame&, void* const)
native latent function UpdateVision();

function bool IsCurrentlyVisible(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function bool IsTargetRecognized(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function Vector GetLastKnownLocationFor(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function Vector GetLastMovingDirectionFor(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function Vector GetLocationWhenLost(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function GetRecentlySeenTargets(out array<ShockPawn> RecentlySeenTargets, float RecentTime)
{
	//native.RecentlySeenTargets;
	//native.RecentTime;	
	@NULL
	@NULL
}

function bool HasEverSeenTarget(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function OnViewerSawPawn(VPawn Viewer, VPawn Seen)
{
	//native.Viewer;
	//native.Seen;	
	@NULL
	@NULL
}

function OnViewerLostPawn(VPawn Viewer, VPawn Lost)
{
	//native.Viewer;
	//native.Lost;	
	@NULL
	@NULL
}

function OnNumLOSChanged(VPawn Viewer, Pawn Seen, int NewNumLOS)
{
	//native.Viewer;
	//native.Seen;
	//native.NewNumLOS;	
	@NULL
	@NULL
	return default.@NULL;
}

defaultproperties
{
	IlluminationRange=(Min=0.1000000,Max=0.3500000)
	LOSVisionRange=(Min=5.0000000,Max=5.0000000)
	MinIlluminationTimeMultiplier=0.0500000
	MidIlluminationTimeMultiplier=0.3000000
	MaxIlluminationTimeMultiplier=1.0000000
	MinLOSVisionTimeMultiplier=0.2000000
	MidLOSVisionTimeMultiplier=1.0000000
	MaxLOSVisionTimeMultiplier=1.0000000
	PlayerNotFacingMultiplier=0.2500000
}