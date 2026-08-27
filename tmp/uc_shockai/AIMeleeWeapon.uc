class AIMeleeWeapon extends AIWeapon
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

function SetHolderAnimationMotionModifier(int HolderAnimationHandle)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xB9
	/*@Error*/
	ShockAI(Holder).SetMotionModifier_MeleeAttack(HolderAnimationHandle, Rotator(__NFUN_216__(NextWeaponAttackInfo.Target.Location, Holder.Location)).Yaw);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	WeaponFireStartOffsetType=4
	WeaponFireStartRotationType=1
	bProjectTargetPosition=true
}