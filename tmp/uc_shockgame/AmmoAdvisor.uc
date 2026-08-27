class AmmoAdvisor extends DifficultyAdvisor
	config(Difficulty);

function int AssessInternal(ShockPlayer Player, out int BaseEase)
{
	local array<DifficultyStat> CheckedStats;

	CheckedStats[0] = DifficultyManager.DifficultyStatsManager.PistolAmmoStats;
	// End:0x99
	if(__NFUN_114__(Player.GetHoldableByClassName('Pistol'), none))
	{
		CheckedStats[0].Value = -1.0000000;
		CheckedStats[0].BaseValue = -1.0000000;
		CheckedStats[1] = DifficultyManager.DifficultyStatsManager.ShotgunAmmoStats;
		// End:0x132
		if(__NFUN_114__(Player.GetHoldableByClassName('Shotgun'), none))
		{
		}
		CheckedStats[1].Value = -1.0000000;
		CheckedStats[1].BaseValue = -1.0000000;
		CheckedStats[2] = DifficultyManager.DifficultyStatsManager.CrossbowAmmoStats;
		// End:0x1CE
		if(__NFUN_114__(Player.GetHoldableByClassName('Crossbow'), none))
		{
			CheckedStats[2].Value = -1.0000000;
		}
		CheckedStats[2].BaseValue = -1.0000000;
		CheckedStats[3] = DifficultyManager.DifficultyStatsManager.ChemicalThrowerAmmoStats;
		// End:0x26A
		if(__NFUN_114__(Player.GetHoldableByClassName('ChemicalThrower'), none))
		{
			CheckedStats[3].Value = -1.0000000;
			CheckedStats[3].BaseValue = -1.0000000;
			CheckedStats[4] = DifficultyManager.DifficultyStatsManager.MachineGunAmmoStats;
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x306
		/*@Error*/
		CheckedStats[4].Value = -1.0000000;
		CheckedStats[4].BaseValue = -1.0000000;
		CheckedStats[5] = DifficultyManager.DifficultyStatsManager.GrenadeLauncherAmmoStats;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3A2
		/*@Error*/
	}
	CheckedStats[5].Value = -1.0000000;
	CheckedStats[5].BaseValue = -1.0000000;
	return DifficultyEvaluator.Evaluate(CheckedStats, DifficultyManager, BaseEase);
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

defaultproperties
{
	AdjustmentRecommendations[0]=(AdjustmentClass=Class'ShockGame.SpawnAmmoAdjustment',ProbabilityTableName="DefaultProbabilityTable",Count=10,Priority=4,Weight=-1.0000000)
	AdjustmentRecommendations[1]=(AdjustmentClass=Class'ShockGame.RemoveAmmoAdjustment',ProbabilityTableName="DefaultProbabilityTable",Count=0,Priority=3,Weight=1.0000000)
	DifficultyEvaluatorClass=Class'ShockGame.AmmoEaseTablesEvaluator'
	DifficultyEvaluatorName="AmmoEaseTablesEvaluator"
	CreditsNeededToBeConsideredRich=100
	AdvisorCategory="Ammo"
}