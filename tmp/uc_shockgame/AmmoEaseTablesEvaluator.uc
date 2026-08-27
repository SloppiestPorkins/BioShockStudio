class AmmoEaseTablesEvaluator extends DifficultyEvaluator
	config(Difficulty)
	perobjectconfig;

var private config name EaseTableName;
var config array<name> WeaponEaseTableNames;
var private transient EaseTable Table;
var transient array<EaseTable> WeaponEaseTables;

function Construct()
{
	local int i;

	log('Difficulty', 4, __NFUN_112__(__NFUN_112__(string(Name), " using "), string(EaseTableName)));
	Table = Class'ShockGame.EaseTable'.static.Allocate(self,, string(EaseTableName)).;
	Construct_Void();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x141
	/*@Error*/
	log('Difficulty', 4, __NFUN_112__(__NFUN_112__(string(Name), " using Weapon Ease Tables"), string(WeaponEaseTableNames[i])));
	WeaponEaseTables[i] = Class'ShockGame.EaseTable'.static.Allocate(self,, string(WeaponEaseTableNames[i])).;
	Construct_Void();
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x7B;
	return;
	@NULL
	Item
	Vector
	@NULL
}

function int Evaluate(array<DifficultyStat> Stats, DifficultyManager DifficultyManager, out int BaseEaseValue)
{
	local float sum, BaseSum;
	local int i, NumValidWeapons;

	AssertWithDescription(__NFUN_154__(Stats.Length, WeaponEaseTableNames.Length), "Number of stats passed into AmmoEaseTablesEvaluator must match the number of ease tables used by it.");
	i = 0;
	// End:0x1A8
	if(__NFUN_150__(i, Stats.Length))
	{
		J0x91:

		// End:0x19A [Loop If]
		if(__NFUN_181__(Stats[i].BaseValue, float(-1)))
		{
			__NFUN_184__(BaseSum, float(WeaponEaseTables[i].GetEaseValue(Stats[i].BaseValue, DifficultyManager)));
			__NFUN_184__(sum, float(WeaponEaseTables[i].GetEaseValue(Stats[i].Value, DifficultyManager)));
			__NFUN_163__(NumValidWeapons);
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x91;
			log('Difficulty', 4, __NFUN_112__(__NFUN_112__("Player have ", string(NumValidWeapons)), " ammo based weapons."));
			// End:0x207
			if(__NFUN_154__(NumValidWeapons, 0))
			{
				BaseEaseValue = 0;
				return 0;
				log('Difficulty', 4, __NFUN_112__("Total ammo score = ", string(BaseSum)));
			}/* !MISMATCHING REMOVE, tried Loop got Type:If Position:0x177! */
		}/* !MISMATCHING REMOVE, tried If got Type:Loop Position:0x091! */
		log('Difficulty', 4, __NFUN_112__("Average ammo score = ", string(__NFUN_172__(BaseSum, float(NumValidWeapons)))));
		log('Difficulty', 4, __NFUN_112__("Total ammo score + Credit Bonus = ", string(sum)));
	}
	log('Difficulty', 4, __NFUN_112__("Average (ammo score + Credit Bonus) = ", string(__NFUN_172__(sum, float(NumValidWeapons)))));
	BaseEaseValue = Table.GetEaseValue(__NFUN_172__(BaseSum, float(NumValidWeapons)), DifficultyManager);
	return Table.GetEaseValue(__NFUN_172__(sum, float(NumValidWeapons)), DifficultyManager);
	return;
	@NULL
	Item
	Item
	@NULL
}
