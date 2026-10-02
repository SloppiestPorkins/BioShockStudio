// BioShock Studio's x86 bridge to the game's FMOD Ex 4.44 runtime.
//
// The game ships a 32-bit fmodex.dll. This utility loads that exact DLL at runtime, asks it to
// decode one FSB subsound, and writes the PCM it returns as a WAV file. It deliberately does not
// carry, redistribute, or reverse engineer FMOD; it is only a narrow client of the public C ABI the
// installed game already exposes. Keeping it out-of-process lets the 64-bit app remain 64-bit.

#define NOMINMAX
#include <windows.h>
#include <algorithm>
#include <cmath>
#include <cstring>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <limits>
#include <string>
#include <vector>

using Result = int;
using FmodSystem = void;
using FmodSound = void;

constexpr Result Ok = 0;
constexpr unsigned int TimeUnitPcmBytes = 0x00000004;
constexpr unsigned int ModeSoftware = 0x00000040;

// Ex 4.44's factory is the pre-header-version form: it takes only the out-system pointer. Passing
// the newer FMOD 5+ header-version argument corrupts the x86 stdcall stack.
using SystemCreate = Result(__stdcall*)(FmodSystem**);
using SystemInit = Result(__stdcall*)(FmodSystem*, int, unsigned int, void*);
using SystemCreateSound = Result(__stdcall*)(FmodSystem*, const char*, unsigned int, void*, FmodSound**);
using SystemClose = Result(__stdcall*)(FmodSystem*);
using SystemRelease = Result(__stdcall*)(FmodSystem*);
using SoundGetNumSubSounds = Result(__stdcall*)(FmodSound*, int*);
using SoundGetSubSound = Result(__stdcall*)(FmodSound*, int, FmodSound**);
using SoundGetName = Result(__stdcall*)(FmodSound*, char*, int);
using SoundGetFormat = Result(__stdcall*)(FmodSound*, int*, int*, int*, int*);
using SoundGetLength = Result(__stdcall*)(FmodSound*, unsigned int*, unsigned int);
using SoundGetDefaults = Result(__stdcall*)(FmodSound*, float*, float*, float*, int*);
using SoundReadData = Result(__stdcall*)(FmodSound*, void*, unsigned int, unsigned int*);
using SoundLock = Result(__stdcall*)(FmodSound*, unsigned int, unsigned int, void**, void**, unsigned int*, unsigned int*);
using SoundUnlock = Result(__stdcall*)(FmodSound*, void*, void*, unsigned int, unsigned int);
using SoundRelease = Result(__stdcall*)(FmodSound*);

struct Api
{
    HMODULE module{};
    SystemCreate systemCreate{};
    SystemInit systemInit{};
    SystemCreateSound systemCreateSound{};
    SystemClose systemClose{};
    SystemRelease systemRelease{};
    SoundGetNumSubSounds soundGetNumSubSounds{};
    SoundGetSubSound soundGetSubSound{};
    SoundGetName soundGetName{};
    SoundGetFormat soundGetFormat{};
    SoundGetLength soundGetLength{};
    SoundGetDefaults soundGetDefaults{};
    SoundReadData soundReadData{};
    SoundLock soundLock{};
    SoundUnlock soundUnlock{};
    SoundRelease soundRelease{};
};

template <typename T>
bool Bind(Api& api, T& target, const char* name)
{
    target = reinterpret_cast<T>(GetProcAddress(api.module, name));
    if (target) return true;
    std::cerr << "fmodex.dll does not export " << name << "\n";
    return false;
}

bool LoadApi(const std::wstring& fmodPath, Api& api)
{
    api.module = LoadLibraryW(fmodPath.c_str());
    if (!api.module)
    {
        std::cerr << "Could not load fmodex.dll (Windows error " << GetLastError() << ").\n";
        return false;
    }

    return Bind(api, api.systemCreate, "FMOD_System_Create")
        && Bind(api, api.systemInit, "FMOD_System_Init")
        && Bind(api, api.systemCreateSound, "FMOD_System_CreateSound")
        && Bind(api, api.systemClose, "FMOD_System_Close")
        && Bind(api, api.systemRelease, "FMOD_System_Release")
        && Bind(api, api.soundGetNumSubSounds, "FMOD_Sound_GetNumSubSounds")
        && Bind(api, api.soundGetSubSound, "FMOD_Sound_GetSubSound")
        && Bind(api, api.soundGetName, "FMOD_Sound_GetName")
        && Bind(api, api.soundGetFormat, "FMOD_Sound_GetFormat")
        && Bind(api, api.soundGetLength, "FMOD_Sound_GetLength")
        && Bind(api, api.soundGetDefaults, "FMOD_Sound_GetDefaults")
        && Bind(api, api.soundReadData, "FMOD_Sound_ReadData")
        && Bind(api, api.soundLock, "FMOD_Sound_Lock")
        && Bind(api, api.soundUnlock, "FMOD_Sound_Unlock")
        && Bind(api, api.soundRelease, "FMOD_Sound_Release");
}

bool Require(Result result, const char* operation)
{
    if (result == Ok) return true;
    std::cerr << operation << " failed with FMOD result " << result << ".\n";
    return false;
}

void WriteU16(std::ofstream& output, std::uint16_t value)
{
    output.put(static_cast<char>(value & 0xFF));
    output.put(static_cast<char>((value >> 8) & 0xFF));
}

void WriteU32(std::ofstream& output, std::uint32_t value)
{
    WriteU16(output, static_cast<std::uint16_t>(value & 0xFFFF));
    WriteU16(output, static_cast<std::uint16_t>((value >> 16) & 0xFFFF));
}

bool WriteWav(const std::filesystem::path& outputPath, const std::vector<std::uint8_t>& pcm,
    unsigned int sampleRate, int channels, int bits)
{
    if (channels < 1 || channels > 32 || bits < 8 || bits % 8 != 0 || sampleRate == 0
        || pcm.size() > std::numeric_limits<std::uint32_t>::max())
    {
        std::cerr << "FMOD returned invalid PCM metadata.\n";
        return false;
    }

    const auto blockAlign = static_cast<std::uint16_t>(channels * (bits / 8));
    const auto byteRate = sampleRate * blockAlign;
    std::ofstream output(outputPath, std::ios::binary);
    if (!output)
    {
        std::cerr << "Could not create " << outputPath.string() << ".\n";
        return false;
    }

    output.write("RIFF", 4);
    WriteU32(output, static_cast<std::uint32_t>(36 + pcm.size()));
    output.write("WAVEfmt ", 8);
    WriteU32(output, 16);
    WriteU16(output, 1); // PCM
    WriteU16(output, static_cast<std::uint16_t>(channels));
    WriteU32(output, sampleRate);
    WriteU32(output, byteRate);
    WriteU16(output, blockAlign);
    WriteU16(output, static_cast<std::uint16_t>(bits));
    output.write("data", 4);
    WriteU32(output, static_cast<std::uint32_t>(pcm.size()));
    output.write(reinterpret_cast<const char*>(pcm.data()), static_cast<std::streamsize>(pcm.size()));
    return output.good();
}

int wmain(int argc, wchar_t** argv)
{
    if (argc != 4 && argc != 5)
    {
        std::wcerr << L"Usage: FmodFsbDecoder.exe <fmodex.dll> <input.fsb> --list\n"
                   << L"   or: FmodFsbDecoder.exe <fmodex.dll> <input.fsb> <output.wav> <subsound-index>\n";
        return 2;
    }

    try
    {
        const std::wstring fmodPath = argv[1];
        const std::wstring inputPath = argv[2];
        const bool listOnly = argc == 4 && std::wstring(argv[3]) == L"--list";
        if (argc == 4 && !listOnly) throw std::invalid_argument("expected --list or an output path and index");
        const std::filesystem::path outputPath = listOnly ? std::filesystem::path() : std::filesystem::path(argv[3]);
        const int index = listOnly ? 0 : std::stoi(argv[4]);
        if (!listOnly && index < 0) throw std::invalid_argument("subsound index must be non-negative");

        Api api;
        if (!LoadApi(fmodPath, api)) return 1;

        FmodSystem* system = nullptr;
        FmodSound* bank = nullptr;
        FmodSound* sound = nullptr;
        int exitCode = 1;
        int subSoundCount = 0;
        int type = 0, format = 0, channels = 0, bits = 0, priority = 0;
        float frequency = 0, volume = 0, pan = 0;
        unsigned int pcmBytes = 0;
        std::vector<std::uint8_t> pcm;
        if (!Require(api.systemCreate(&system), "FMOD_System_Create")
            || !Require(api.systemInit(system, 32, 0, nullptr), "FMOD_System_Init")
            // ReadData is a software-decoder operation. The FSB itself does not state a playback
            // preference, so make that requirement explicit instead of depending on the current
            // Windows audio driver's hardware capability.
            || !Require(api.systemCreateSound(system, std::filesystem::path(inputPath).string().c_str(), ModeSoftware, nullptr, &bank), "FMOD_System_CreateSound"))
            goto cleanup;

        if (!Require(api.soundGetNumSubSounds(bank, &subSoundCount), "FMOD_Sound_GetNumSubSounds")) goto cleanup;
        if (listOnly)
        {
            for (int i = 0; i < subSoundCount; ++i)
            {
                FmodSound* listed = nullptr;
                char name[512]{};
                if (!Require(api.soundGetSubSound(bank, i, &listed), "FMOD_Sound_GetSubSound")) goto cleanup;
                Result named = api.soundGetName(listed, name, static_cast<int>(sizeof(name)));
                if (named != Ok) name[0] = '\0';
                std::cout << i << "\t" << name << "\n";
                api.soundRelease(listed);
            }
            exitCode = 0;
            goto cleanup;
        }
        if (index >= subSoundCount)
        {
            std::cerr << "Subsound index " << index << " is outside this bank's " << subSoundCount << " samples.\n";
            goto cleanup;
        }
        if (!Require(api.soundGetSubSound(bank, index, &sound), "FMOD_Sound_GetSubSound")) goto cleanup;

        if (!Require(api.soundGetFormat(sound, &type, &format, &channels, &bits), "FMOD_Sound_GetFormat")
            || !Require(api.soundGetDefaults(sound, &frequency, &volume, &pan, &priority), "FMOD_Sound_GetDefaults")
            || !Require(api.soundGetLength(sound, &pcmBytes, TimeUnitPcmBytes), "FMOD_Sound_GetLength"))
            goto cleanup;

        if (frequency <= 0 || frequency > std::numeric_limits<unsigned int>::max())
        {
            std::cerr << "FMOD returned invalid sample rate " << frequency << ".\n";
            goto cleanup;
        }

        pcm.resize(pcmBytes);
        unsigned int total = 0;
        bool readDataSucceeded = true;
        while (total < pcm.size())
        {
            const auto requested = static_cast<unsigned int>(std::min<std::size_t>(65536, pcm.size() - total));
            unsigned int received = 0;
            if (api.soundReadData(sound, pcm.data() + total, requested, &received) != Ok)
            {
                readDataSucceeded = false;
                break;
            }
            if (received == 0)
            {
                readDataSucceeded = false;
                break;
            }
            total += received;
        }

        // FMOD Ex exposes an already-decompressed non-streaming sound through Lock rather than
        // ReadData on some builds. Both routes return FMOD-owned PCM; this is a compatibility
        // fallback, not a reinterpretation of FSB bytes.
        if (!readDataSucceeded)
        {
            void* first = nullptr;
            void* second = nullptr;
            unsigned int firstBytes = 0, secondBytes = 0;
            if (!Require(api.soundLock(sound, 0, pcmBytes, &first, &second, &firstBytes, &secondBytes), "FMOD_Sound_Lock")) goto cleanup;
            if (firstBytes + secondBytes != pcm.size())
            {
                api.soundUnlock(sound, first, second, firstBytes, secondBytes);
                std::cerr << "FMOD lock returned " << firstBytes + secondBytes << " of " << pcm.size() << " declared PCM bytes.\n";
                goto cleanup;
            }
            std::memcpy(pcm.data(), first, firstBytes);
            if (secondBytes) std::memcpy(pcm.data() + firstBytes, second, secondBytes);
            api.soundUnlock(sound, first, second, firstBytes, secondBytes);
            total = pcmBytes;
        }

        if (!WriteWav(outputPath, pcm, static_cast<unsigned int>(std::lround(frequency)), channels, bits)) goto cleanup;
        std::cout << "Decoded " << outputPath.string() << ": " << total << " PCM bytes, "
                  << std::lround(frequency) << " Hz, " << channels << " channels, " << bits << " bit.\n";
        exitCode = 0;

    cleanup:
        if (sound) api.soundRelease(sound);
        if (bank) api.soundRelease(bank);
        if (system) { api.systemClose(system); api.systemRelease(system); }
        FreeLibrary(api.module);
        return exitCode;
    }
    catch (const std::exception& error)
    {
        std::cerr << "Invalid arguments: " << error.what() << "\n";
        return 2;
    }
}
