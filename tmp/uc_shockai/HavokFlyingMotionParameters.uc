class HavokFlyingMotionParameters extends DeletableObject
	native
	config(AI)
	perobjectconfig;

var private config float KeepOffFloorMultiplier;
var private config float MaxThrust;
var private config float LateralThrustModifier;
var private config float MomentumTorqueModifier;
var private config float MinNextHeadingAngleLookahead;
var private config float MaxNextHeadingAngleLookahead;
var private config float MinAngleExceededLookAheadDistance;

defaultproperties
{
	KeepOffFloorMultiplier=0.5000000
	MaxThrust=4.0000000
	LateralThrustModifier=1.5000000
	MomentumTorqueModifier=0.2500000
	MinNextHeadingAngleLookahead=45.0000000
	MaxNextHeadingAngleLookahead=135.0000000
	MinAngleExceededLookAheadDistance=5.0000000
}