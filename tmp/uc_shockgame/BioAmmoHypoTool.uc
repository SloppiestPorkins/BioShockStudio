class BioAmmoHypoTool extends Actor
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var config name InjectingEveAnimationName;

defaultproperties
{
	InjectingEveAnimationName="Plunge"
	DrawType=2
	bHidden=true
	bInGameRenderable=true
	Mesh=SkeletalMesh'ShockGame.WP_PlasmidEquip.PlasmidEquipMESH'
}