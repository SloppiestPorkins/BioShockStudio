class GPSArrow extends Actor
	native
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

enum EAnimationState
{
	AnimState_None,                 // 0
	AnimState_In,                   // 1
	AnimState_Out                   // 2
};

var float AnimationStartTime;
var float TweenTotalTime;
var float PulseTotalTime;
var float PowerCurveExponent;
var float NumPulses;
var float PulseYShift;
var float PulseAmplitude;
var float CurrentOpacity;
var float PulseSizeModifier;
var GPSArrow.EAnimationState AnimState;

// Export UGPSArrow::execAnimateIn(FFrame&, void* const)
native function AnimateIn();

// Export UGPSArrow::execAnimateOut(FFrame&, void* const)
native function AnimateOut();

function UpdateAnimation(float DeltaTime)
{
	//native.DeltaTime;	
	@NULL
}

function Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	UpdateAnimation(DeltaTime);
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	TweenTotalTime=1.0000000
	PulseTotalTime=5.0000000
	PowerCurveExponent=0.2000000
	NumPulses=10.0000000
	PulseYShift=0.7500000
	PulseAmplitude=0.3000000
	CurrentOpacity=1.0000000
	PulseSizeModifier=0.1500000
	DrawType=8
	StaticMesh=StaticMesh'ShockGame.GPS_arrow.GPS_arrow'
	bHidden=true
	bInGameRenderable=true
	DrawScale=0.2000000
	bBlockZeroExtentTraces=false
	bBlockNonZeroExtentTraces=false
}