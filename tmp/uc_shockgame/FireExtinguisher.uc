class FireExtinguisher extends VisualFXProxyReactiveActor
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Collision,Havok);

state HACK_Wait_One_Tick_To_Update_Havok_Representation
{Begin:

	HavokInitActor();
	stop;	
	@NULL
}

defaultproperties
{
	LifeSpan=10.0000000
}