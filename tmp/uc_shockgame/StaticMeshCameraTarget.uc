class StaticMeshCameraTarget extends StaticMeshActor implements IPhotographTarget
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Force,LightColor,Lighting,Object,Sound);

var int PhotoCount;

function name GetPhotographLabel()
{
	return Label;
	return;
	@NULL
}

function GetAnimationPhotoScore(int Score)
{
	return;
}

function int SetAnimationPhotoScore()
{
	return 0;
	return;
}

function int PhotographedCount()
{
	return PhotoCount;
	return;
	@NULL
}

function OnPhotoTaken()
{
	__NFUN_163__(PhotoCount);
	return;
	@NULL
}

function bool ApplyDeadPenalty()
{
	return false;
	return;
}

function RegisterPhotographTarget()
{
	log(,, __NFUN_112__("Registering photograph target with name ", string(self.Name)));
	ShockGameInfo(Level.Game).RegisterPhotographTarget(self);
	return;
	@NULL
	Item
	Item
	@NULL
}

function UnregisterPhotographTarget()
{
	log(,, __NFUN_112__("Unregistering photograph target with name ", string(self.Name)));
	ShockGameInfo(Level.Game).UnregisterPhotographTarget(self);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PostLoadGame()
{
	super(Actor).PostLoadGame();
	RegisterPhotographTarget();
	return;
	@NULL
}

function PostBeginPlay()
{
	super(Actor).PostBeginPlay();
	RegisterPhotographTarget();
	return;
	@NULL
}

function Destroyed()
{
	UnregisterPhotographTarget();
	super(Actor).Destroyed();
	return;
	@NULL
}

defaultproperties
{
	StaticMesh=StaticMesh'ShockGame.SimpleShapes.Cube256Diameter'
}