class SecurityCameraSpawner extends SpawnerBase
	native
	config(Spawning)
	placeable
	hidecategories(DrawScale3D,DisplayAdvanced,Advanced,Collision,Display,Force,Havok,LightColor,Lighting,Sound);

var(Camera) Class<ShockAI> CameraType;
var(Camera) private config float LeftYawLimit;
var(Camera) private config float RightYawLimit;
var(Camera) private config float UpperPitchLimit;
var(Camera) private config float LowerPitchLimit;
var(Camera) private config float DefaultPitchDegrees;
var(Camera) private config float PanningLeftYawLimit;
var(Camera) private config float PanningRightYawLimit;
var(Camera) private config float FOV;
var(Camera) private config float SightDistance;
var(Camera) private config bool StartHackedByPlayer;
var(Camera) export editinline Container LootContainer;
var(Camera) private name SpawnedCameraLabel;
var(Camera) private editconst SecurityCameraLight Spotlight;
var(Hacking) private name HackInfoName;
var(Hacking) private bool CanBeHacked;

function OutputTypesToBox(LevelInfo Level, out array< Class<ShockAI> > S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	SpawningManager(Level.SpawningManager).DisplaySecurityCameraTypes(Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function AllHackInfoNames(LevelInfo Level, out array<name> S)
{
	local int i;
	local HackInfoList HackInfoList;

	HackInfoList = Class'ShockGame.HackInfoList'.static.Allocate(self).;
	Construct_Void();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA3
	/*@Error*/
	S[i] = HackInfoList.HackInfoName[i];
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x3C;
	HackInfoList.__NFUN_200__();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function string DisplayAITypeName(Class<ShockAI> AIClass)
{
	// End:0x2B
	if(__NFUN_119__(AIClass, none))
	{
		return string(AIClass.Name);
		goto J0x3B;
		return "Class Not Set";
	}
	return;
	@NULL
	CommanderAction
	J0x3B:

	CommanderAction
}

defaultproperties
{
	LeftYawLimit=-30.0000000
	RightYawLimit=30.0000000
	LowerPitchLimit=-65.0000000
	DefaultPitchDegrees=-20.0000000
	PanningLeftYawLimit=-30.0000000
	PanningRightYawLimit=30.0000000
	FOV=60.0000000
	SightDistance=1000.0000000
	HackInfoName="SecurityCameraDefault"
	CanBeHacked=true
	DrawType=2
}