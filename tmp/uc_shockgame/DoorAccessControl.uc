class DoorAccessControl extends DoorAttachment
	abstract
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Force,LightColor,Lighting,Object,Sound);

var(Door) name DoorLabel;
var private ShockDoor TheDoor;

function PreBeginPlay()
{
	super(Actor).PreBeginPlay();
	log('Doors', 4, __NFUN_112__(string(self), "---DoorAccessControl::PreBeginPlay()."));
	log('Doors', 5, __NFUN_112__("...DoorLabel=", string(DoorLabel)));
	TheDoor = ShockDoor(findByLabel(Class'ShockGame.ShockDoor', DoorLabel));
	AssertWithDescription(__NFUN_119__(TheDoor, none), __NFUN_112__(string(self), " does not have its DoorLabel set to a valid door."));
	log('Doors', 5, __NFUN_112__("...TheDoor=", string(TheDoor)));
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	DrawType=2
	Mesh=SkeletalMesh'SimpleAnim.SimpleAnim'
	bCollideActors=true
}