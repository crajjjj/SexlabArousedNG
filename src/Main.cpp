#include "Papyrus.h"
#include <stddef.h>
#include <ArousalManager.h>
#include <ArousalData.h>

using namespace RE::BSScript;
using namespace SKSE;
using namespace SKSE::log;
using namespace SKSE::stl;
 
namespace {
    void InitializePapyrus() {
        log::trace("Initializing Papyrus binding...");
        if (GetPapyrusInterface()->Register(SLA::RegisterFunctions)) {
            log::info("Papyrus functions bound.");
        } else {
            stl::report_and_fail("Failure to register Papyrus bindings.");
        }
    }

    void InitializeSerialization() {
        log::trace("Initializing cosave serialization...");
        auto* serde = GetSerializationInterface();
        serde->SetUniqueID(_byteswap_ulong('SLAN'));
        serde->SetSaveCallback(SLA::ArousalManager::OnGameSaved);
        serde->SetRevertCallback(SLA::ArousalManager::OnRevert);
        serde->SetLoadCallback(SLA::ArousalManager::OnGameLoaded);
        log::info("Cosave serialization initialized.");
    }
}

SKSEPluginLoad(const LoadInterface* skse) {
    // Init() sets up the <SKSE logs>\SexlabArousedNG.log logger itself (CommonLibSSE-NG v7+)
    // and prints the "<name> v<version>" line; a plugin-side spdlog setup before it was
    // replaced by it and never took effect.
    Init(skse);
    auto* plugin = PluginDeclaration::GetSingleton();
    log::info("{} {} is loading...", plugin->GetName(), plugin->GetVersion());
    SLA::InitializeRandomEngine();
    InitializeSerialization();
    InitializePapyrus();

    log::info("{} has finished loading.", plugin->GetName());
    return true;
}
