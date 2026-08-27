class EaseTable extends Object
	native
	config(Difficulty)
	perobjectconfig;

struct native atomic EaseEntry
{
	var int EaseValue;
	var DifficultyFloat Value;
};

var config array<EaseEntry> Entries;

function int GetEaseValue(float Value, DifficultyManager DifficultyManager)
{
	local int i, EntryIndex;

	i = 0;
	// End:0x8D
	if(__NFUN_150__(i, Entries.Length))
	{
		// End:0x7F
		if(__NFUN_178__(DifficultyManager.GetDifficultyFloat(Entries[i].Value), Value))
		{
			EntryIndex = i;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			log('Difficulty', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Getting Ease Value ", string(Entries[EntryIndex].EaseValue)), " from value "), string(Value)), " in Table "), string(Name)));
		}
	}
	return Entries[EntryIndex].EaseValue;
	return;
	@NULL
	Item
	Item
	@NULL
}

function float GetValue(float EaseValue, DifficultyManager DifficultyManager)
{
	local int i, EntryIndex;

	i = 0;
	// End:0x78
	if(__NFUN_150__(i, Entries.Length))
	{
		// End:0x6A
		if(__NFUN_178__(float(Entries[i].EaseValue), EaseValue))
		{
			EntryIndex = i;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			log('Difficulty', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Getting Value ", string(DifficultyManager.GetDifficultyFloat(Entries[EntryIndex].Value))), " from "), string(EaseValue)), " in Table "), string(Name)));
		}
	}
	return DifficultyManager.GetDifficultyFloat(Entries[EntryIndex].Value);
	return;
	@NULL
	Item
	Item
	@NULL
}
