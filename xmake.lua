-- xmake build for the SKSE plugin -- alternative to the CMake + vcpkg build
-- (CMakeLists.txt); both consume the same CommonLibSSE-NG submodule at
-- lib/commonlibsse-ng (alandtse fork, pinned v7.0.0, Skyrim 1.7.99 capable).
-- NG's build deps (spdlog, directxtk, ...) come from xmake-repo here instead
-- of vcpkg. Papyrus tooling (bethesda-skyrim-scripts, skse scripts) is only
-- provided by the vcpkg manifest -- xmake builds just the DLL.
--
--   xmake f -m releasedbg   # configure (first run compiles CommonLibSSE-NG)
--   xmake                   # build; DLL is deployed to dist/Core/SKSE/Plugins
--
-- Optional: set COMMONLIB_PREBUILT=1 to let NG fetch its prebuilt release
-- bundle instead of compiling from source (see lib/commonlibsse-ng/xmake.lua).

set_xmakever("3.0.0")

set_version("3.3.5") -- keep in sync with CMakeLists.txt project VERSION (see CLAUDE.md)
set_license("Apache-2.0")

add_rules("mode.debug", "mode.releasedbg")

-- Match the CMake build's dynamic CRT (vcpkg triplet x64-windows-skse).
if is_mode("debug") then
    set_runtimes("MDd")
else
    set_runtimes("MD")
    set_policy("build.optimization.lto", true) -- CMAKE_INTERPROCEDURAL_OPTIMIZATION equivalent
end

includes("lib/commonlibsse-ng")

-- After the include: CommonLibSSE-NG's own xmake.lua calls set_project() too,
-- and the last call wins -- restate ours so the generated version resource
-- carries this project's name.
set_project("SexlabArousedNG")

target("SexlabArousedNG", function()
    add_deps("commonlibsse-ng")
    add_rules("commonlibsse-ng.plugin", {
        name = "SexlabArousedNG",
        author = "fishburger, Lupine, Voodoh, ponzipyramid, crajjjj",
        description = "Next generation arousal for Sexlab and Ostim",
    })

    add_files("src/*.cpp")
    add_includedirs("include", "src")
    set_pcxxheader("src/PCH.h")

    -- SLA_BUILDING_DLL turns the SLA_* declarations in include/ArousalAPI.h into
    -- real exports (see the note in CMakeLists.txt); the rest mirror the CMake
    -- presets' platform defines.
    add_defines("SLA_BUILDING_DLL", "WIN32_LEAN_AND_MEAN", "NOMINMAX", "UNICODE", "_UNICODE")

    -- Same deployment as the CMake POST_BUILD step: ONLY the DLL to dist.
    after_build(function(target)
        local dist = path.join(os.projectdir(), "dist", "Core", "SKSE", "Plugins")
        os.mkdir(dist)
        os.cp(target:targetfile(), dist)
    end)
end)
