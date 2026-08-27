class SpawnAmmoAdjustment extends SpawnAdjustment
	config(Difficulty);

struct atomic AmmoStackSize
{
	var name Level;
	var int PistolAmmoStackSize;
	var int ShotGunAmmoStackSize;
	var int ChemicalThrowerAmmoStackSize;
	var int CrossbowAmmoStackSize;
	var int GrenadeLauncherAmmoStackSize;
	var int MachineGunAmmoStackSize;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var config array<AmmoStackSize> AmmoStackSizes;

function int GetStackSizeForWeapon(Weapon Weapon, AmmoStackSize AmmoStackSize)
{
	switch(Weapon.Class)
	{
		// End:0x3F
		case Class'ShockGame.Pistol':
			return AmmoStackSize.PistolAmmoStackSize;
			// End:0x66
			case Class'ShockGame.Shotgun':
				return AmmoStackSize.ShotGunAmmoStackSize;
				// End:0x8D
				case Class'ShockGame.Crossbow':
				return AmmoStackSize.CrossbowAmmoStackSize;
				// End:0xB4
				case Class'ShockGame.ChemicalThrower':
					return AmmoStackSize.ChemicalThrowerAmmoStackSize;
				// End:0xDB
				case Class'ShockGame.GrenadeLauncher':
					return AmmoStackSize.GrenadeLauncherAmmoStackSize;
					// End:0x102
					case Class'ShockGame.MachineGun':
						return AmmoStackSize.MachineGunAmmoStackSize;
					// End:0xFFFF
					default:
						return;
						break;
				}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x06C! */
				@NULL
				Item
				ShockPawn
				@NULL/* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x000! */
}

function float CalculateSpawnWeight(ShockPlayer Player, Weapon Weapon)
{
	local int i;
	local float Max, Have, TotalPercentage;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x134
	/*@Error*/
	Have = float(Player.GetNumberOfItems(Weapon.AvailableAmmoTypes[i]));
	Max = float(Weapon.AvailableAmmoTypes[i].default.MaximumStackSize);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x107
	/*@Error*/
	return 0.0000000;
	__NFUN_184__(TotalPercentage, __NFUN_172__(Have, Max));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return __NFUN_175__(1.0000000, __NFUN_172__(TotalPercentage, float(Weapon.AvailableAmmoTypes.Length)));
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function GetSpawnParameters(out Class<Item> ItemClass, out int StackSize)
{
	local Controller Controller;
	local ShockPlayer Player;
	local array<Holdable> Holdables;
	local int i;
	local Weapon Weapon;
	local int DefaultIndex;
	local float TotalWeight, SelectedWeight;
	local array<Weapon> Weapons;
	local array<float> Weights;

	Controller = DifficultyManager.GetGameDriver().GetLevel().GetLocalPlayerController();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4B8
	/*@Error*/
	Player = ShockPlayer(Controller.Pawn);
	Holdables = Player.GetAvailableHoldables();
	i = 0;
	// End:0x22C
	if(__NFUN_150__(i, Holdables.Length))
	{
		Weapon = Weapon(Holdables[i]);
		// End:0x21E
		if(__NFUN_130__(__NFUN_130__(__NFUN_119__(Weapon, none), __NFUN_119__(Weapon.Class, Class'ShockGame.Wrench')), __NFUN_119__(Weapon.Class, Class'ShockGame.ResearchCamera')))
		{
			Weights[Weapons.Length] = CalculateSpawnWeight(Player, Weapon);
			log('Difficulty', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("Weapon ", string(Weapon.Name)), " has ammo spawn weight of "), string(Weights[Weapons.Length])));
			__NFUN_184__(TotalWeight, Weights[Weapons.Length]);
			Weapons[Weapons.Length] = Weapon;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0xAE;
			// End:0x251
			if(__NFUN_132__(__NFUN_154__(Weapons.Length, 0), __NFUN_180__(TotalWeight, float(0))))
			{
				return;
				SelectedWeight = float(__NFUN_167__(int(TotalWeight)));
				Weapon = none;
				i = 0;
				// End:0x361
				if(__NFUN_150__(i, Weapons.Length))
				{
					// End:0x2E3
					if(__NFUN_130__(__NFUN_114__(Weapon, none), __NFUN_177__(Weights[i], 0.0000000)))
					{
						Weapon = Weapons[i];
						__NFUN_185__(SelectedWeight, Weights[i]);
						// End:0x353
						if(__NFUN_130__(__NFUN_176__(SelectedWeight, 0.0000000), __NFUN_177__(Weights[i], 0.0000000)))
						{
						}
					}
					Weapon = Weapons[i];
				}
				goto J0x361;
				__NFUN_163__(i);
				goto J0x280;
				ItemClass = Weapon.GetDefaultAmmoSelection();
				i = 0;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x488
				/*@Error*/
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x3ED
				/*@Error*/
				DefaultIndex = i;
				goto J0x47A;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x47A
				/*@Error*/
			}
			StackSize = GetStackSizeForWeapon(Weapon, AmmoStackSizes[i]);
			return;
			__NFUN_163__(i);
			goto J0x38D;
			StackSize = GetStackSizeForWeapon(Weapon, AmmoStackSizes[DefaultIndex]);
			return;
			@NULL
		}
		Item
		DifficultyAdjustment
	}
	J0x361:

	@NULL
}

defaultproperties
{
	AmmoStackSizes[0]=(Level="Default",PistolAmmoStackSize=8,ShotGunAmmoStackSize=6,ChemicalThrowerAmmoStackSize=50,CrossbowAmmoStackSize=5,GrenadeLauncherAmmoStackSize=3,MachineGunAmmoStackSize=0)
	MinSpawnRate=(Low=30.0000000,Normal=100.0000000,High=280.0000000,Extreme=280.0000000)
	MaxSpawnRate=(Low=60.0000000,Normal=140.0000000,High=320.0000000,Extreme=320.0000000)
}