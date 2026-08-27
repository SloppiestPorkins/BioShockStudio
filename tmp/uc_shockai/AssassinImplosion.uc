class AssassinImplosion extends HavokForceActorPreset
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Lighting,Display,Advanced,Events,Object,Sound,Collision,Havok,Force,Pressure,Animation);

defaultproperties
{
	// Reference: HavokForceTypeConstantForce'ShockAI.HavokPhysicsSpecial.AssassinImplosion.HavokForceTypeConstantForce_7'
	begin object name="HavokForceTypeConstantForce_7" class=Engine.HavokForceTypeConstantForce
		Force=-100000.0000000
		CheckpointTypePadding=7602293
	end object
	ForceType=HavokForceTypeConstantForce_7
	// Reference: HavokForceSphere'ShockAI.HavokPhysicsSpecial.AssassinImplosion.HavokForceSphere_7'
	begin object name="HavokForceSphere_7" class=Engine.HavokForceSphere
		Radius=200.0000000
		CheckpointTypePadding=7602293
	end object
	ForceShape=HavokForceSphere_7
}