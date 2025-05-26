#include <SKSE/SKSE.h>
#include "SerializationHelper.h"

void Serialization::WriteString(SKSE::SerializationInterface* intfc, std::string const& string) {
    uint32_t length = static_cast<uint32_t>(string.length());
    intfc->WriteRecordData(&length, sizeof(length));
    intfc->WriteRecordData(string.c_str(), length);
}

std::string Serialization::ReadString(SKSE::SerializationInterface* intfc, uint32_t& length) {
    uint32_t strlength = ReadDataHelper<uint32_t>(intfc, length);
    if (strlength > length) throw std::length_error("savegame data ended unexpected");
    length -= strlength;
    char* buf = new char[strlength + 1];
    intfc->ReadRecordData(buf, strlength);
    buf[strlength] = '\0';
    std::string result(buf);
    delete[] buf;
    return result;
}
