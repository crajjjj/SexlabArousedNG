#pragma once

#include <SKSE/SKSE.h>

namespace Serialization {
    void WriteString(SKSE::SerializationInterface* intfc, std::string const& string);

    template <typename Ty>
    void WriteContainerData(SKSE::SerializationInterface* intfc, Ty const& container) {
        uint32_t size = static_cast<uint32_t>(container.size());
        intfc->WriteRecordData(&size, sizeof(size));
        for (auto const& kvp : container) intfc->WriteRecordData(&kvp, sizeof(kvp));
    }
    template <typename Ty>
    Ty ReadDataHelper(SKSE::SerializationInterface* intfc, uint32_t& length) {
        uint32_t size = sizeof(Ty);
        if (size > length) throw std::length_error("savegame data ended unexpected");
        length -= size;
        Ty result;
        intfc->ReadRecordData(&result, size);
        return result;
    }
    std::string ReadString(SKSE::SerializationInterface* intfc, uint32_t& length);
}
