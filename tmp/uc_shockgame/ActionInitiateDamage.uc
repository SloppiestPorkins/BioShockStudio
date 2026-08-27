class ActionInitiateDamage extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name DamagerLabel;
var travel name SourceLabel;
var travel name TargetLabel;
var travel Class<Ammunition> DamageClass;
var travel float OverrideInitialVelocity;

function Variable execute()
{
	local Actor Damager, Source, Target;
	local IProvideDamageData DamageData;
	local Class<DamageFactory> DamageFactoryClass;
	local DamageFactory DamageFactory;
	local Rotator AttackRotation;
	local Vector DummyEndLocation;

	super.execute();
	DamageData = IProvideDamageData(ShockGameInfo(parentScript.Level.Game).GetItemFromClass(DamageClass));
	Damager = findByLabel(Class'Engine.Actor', DamagerLabel);
	Source = findByLabel(Class'Engine.Actor', SourceLabel);
	Target = findByLabel(Class'Engine.Actor', TargetLabel);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x354
	/*@Error*/
	// End:0x16B
	if(__NFUN_119__(IProvideProjectileDamageData(DamageData), none))
	{
		// End:0x155
		if(__NFUN_177__(OverrideInitialVelocity, float(0)))
		{
			IProvideProjectileDamageData(DamageData).SetInitialVelocity(OverrideInitialVelocity);
			DamageFactoryClass = Class'ShockGame.ProjectileDamageFactory';
			goto J0x1F2;
			// End:0x199
			if(__NFUN_119__(IProvideTraceDamageData(DamageData), none))
			{
				DamageFactoryClass = Class'ShockGame.TraceDamageFactory';
				goto J0x1F2;
				// End:0x1C7
				if(__NFUN_119__(IProvideMeleeDamageData(DamageData), none))
				{
					DamageFactoryClass = Class'ShockGame.MeleeDamageFactory';
					goto J0x1F2;
					// End:0x1F2
					if(__NFUN_119__(IProvideEmitterDamageData(DamageData), none))
					{
						DamageFactoryClass = Class'ShockGame.EmitterDamageFactory';
						AssertWithDescription(__NFUN_119__(DamageFactoryClass, none), "Unrecognized damageData class.  Cannot initiate damage.");
					}
				}
			}
			DamageFactory = ShockGameInfo(Source.Level.Game).GetDamageFactory(DamageFactoryClass);
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2C0
		/*@Error*/
		AttackRotation = Source.Rotation;
		goto J0x2FA;
		AttackRotation = Rotator(__NFUN_216__(Target.Location, Source.Location));
	}
	DamageFactory.InitiateDamage(Damager, Source.Location, AttackRotation, DamageData, 'None', DummyEndLocation);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Initiate Damage from location marked by '", string(SourceLabel)), "' towards the location marked by '"), string(TargetLabel)), "'");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Initiate Damage."
	actionHelp="Initiates Damage."
}