class ThresholdEvaluator extends DifficultyEvaluator
	config(Difficulty)
	perobjectconfig;

var config array<DifficultyFloat> Thresholds;

function int Evaluate(array<DifficultyStat> Stats, DifficultyManager DifficultyManager, out int BaseEaseValue)
{
	local int i, Ease;

	i = 0;
	// End:0x10D
	if(__NFUN_150__(i, Stats.Length))
	{
		log('DifficultyAdvisor', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("Threshold :", string(DifficultyManager.GetDifficultyFloat(Thresholds[i]))), " Value:"), string(Stats[i].Value)));
		// End:0xFF
		if(__NFUN_177__(Stats[i].BaseValue, DifficultyManager.GetDifficultyFloat(Thresholds[i])))
		{
			Ease = 0;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			Ease = -1;
			BaseEaseValue = Ease;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x23C
			/*@Error*/
			log('DifficultyAdvisor', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("Threshold :", string(DifficultyManager.GetDifficultyFloat(Thresholds[i]))), " Value:"), string(Stats[i].Value)));
		}
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x22E
	/*@Error*/
	Ease = 0;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x13A;
	Ease = -1;
	return Ease;
	return;
	@NULL
	Item
	Item
	@NULL
}
