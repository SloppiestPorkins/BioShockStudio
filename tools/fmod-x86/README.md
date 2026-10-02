# FMOD x86 stream decoder

`FmodFsbDecoder.cpp` is a deliberately small 32-bit helper for the game's bundled FMOD Ex 4.44.53
runtime. The 64-bit application cannot load `Build/Final/fmodex.dll`; this process can. It receives
the runtime path, one FSB5 bank, one subsound index, and writes only the PCM that FMOD returns as a
standard WAV file.

It does not include FMOD, copy the game's DLL, reinterpret FSB bytes, or guess a WAV header. The
metadata and PCM are both reported by the installed FMOD runtime, and the output is rejected if its
declared PCM byte count cannot be read in full.

Build from an x86 Visual C++ developer prompt:

```bat
cl /nologo /std:c++17 /EHsc /O2 FmodFsbDecoder.cpp /Fe:FmodFsbDecoder.exe
```

Example:

```bat
FmodFsbDecoder.exe "G:\SteamLibrary\steamapps\common\BioShock Remastered\Build\Final\fmodex.dll" "G:\SteamLibrary\steamapps\common\BioShock Remastered\ContentBaked\pc\Sounds_Windows\streams_0_audio.fsb" output.wav 0
```
