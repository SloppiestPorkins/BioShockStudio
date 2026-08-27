class MaximumSecurityTurret extends Turret
	abstract
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var private config name GrenadeLauncherAnimationName;
var private config float GrenadeLauncherAnimationEaseOutTime;
var private int GrenadeLauncherAnimationHandle;

function StartEngine()
{
	super.StartEngine();
	GrenadeLauncherAnimationHandle = PlayAnimationOnChannel(2, GrenadeLauncherAnimationName, 8);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StopEngine(float EaseOutTime)
{
	super.StopEngine(EaseOutTime);
	FlatEaseOutAnimation(GrenadeLauncherAnimationHandle, GrenadeLauncherAnimationEaseOutTime);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	GrenadeLauncherAnimationName="WheelOn"
	GrenadeLauncherAnimationEaseOutTime=4.0000000
}