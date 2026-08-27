class SecurityCameraLight extends Light
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Force,Collision,Object,Sound,Movement,Havok,Events);

var(Lighting) bool LightConeAutoMatchesCameraFOV;

defaultproperties
{
	LightBrightness=2.0000000
	LightRadius=2048.0000000
	LightCone=4
	bImportantDynamicLight=true
	bCastsShadowMapShadows=true
	Texture=Texture'Engine_res.S_Light_SecurityCamera'
}