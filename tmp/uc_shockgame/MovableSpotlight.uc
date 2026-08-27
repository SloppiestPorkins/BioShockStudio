class MovableSpotlight extends Light
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Force,Collision,Object,Sound,Movement,Havok,Events);

var(Spotlight) private bool StartsOn;
var(Spotlight) private Class<MovableSpotlightController> ControllerClass;
var(Spotlight) private Vector ControllerLocationOffset;
var(Spotlight) private Rotator ControllerRotationOffset;
var private MovableSpotlightController OurController;
var private bool HasTriggeredSpotlightOn;

function string DisplayAITypeName(Class<MovableSpotlightController> SpecifiedControllerClass)
{
	// End:0x2B
	if(__NFUN_119__(SpecifiedControllerClass, none))
	{
		return string(SpecifiedControllerClass.Name);
		goto J0x3B;
		return "Class Not Set";
	}
	return;
	@NULL
	Item
	J0x3B:

	Item
}

function PostBeginPlay()
{
	OurController = __NFUN_278__(ControllerClass,,, __NFUN_215__(Location, ControllerLocationOffset),, true);
	assert(__NFUN_119__(OurController, none));
	OurController.Initialize(self, StartsOn, ControllerRotationOffset);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function Destroyed()
{
	OurController.__NFUN_279__();
	super(Actor).Destroyed();
	return;
	@NULL
	Item
}

function SetSpotlightState(bool SpotlightOn)
{
	// End:0x7A
	if(SpotlightOn)
	{
		SetLightType(Class.default.LightType);
		// End:0x77
		if(__NFUN_129__(HasTriggeredSpotlightOn))
		{
			OurController.TriggerEffectEvent('SpotlightOn',,,,,,, OurController);
			HasTriggeredSpotlightOn = true;
			goto J0xD6;
			SetLightType(0);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xD6
			/*@Error*/
			OurController.ClearAttachedEffectActorsArray();
		}
	}
	OurController.UnTriggerEffectEvent('SpotlightOn');
	HasTriggeredSpotlightOn = false;
	return;
	@NULL
	Item
	Item
	@NULL
}

function SetActorTracking(Actor newActorToTrack)
{
	assert(__NFUN_119__(OurController, none));
	OurController.SetActorTracking(newActorToTrack);
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	ControllerClass=Class'ShockGame.MovableSpotlightController'
	LightBrightness=2.0000000
	LightRadius=2048.0000000
	LightCone=4
	bImportantDynamicLight=true
	bCastsShadowMapShadows=true
	Texture=Texture'ShockGame.Engine_res.S_Light_SecurityCamera'
	bDirectional=true
}