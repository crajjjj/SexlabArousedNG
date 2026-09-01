-- Build for the SKSE plugin (xmake 3.0+, MSVC). CommonLibSSE-NG (alandtse fork,
-- pinned v7.0.0, Skyrim 1.7.99 capable) is vendored as a git submodule at
-- lib/commonlibsse-ng; its build deps (spdlog, directxtk, ...) come from
-- xmake-repo. Papyrus scripts are compiled separately (skyrimse.ppj / Pyro) --
-- this builds just the DLL.
--
--   xmake f -m release   # configure (first run compiles CommonLibSSE-NG)
--   xmake                # build; DLL is deployed to dist/Core/SKSE/Plugins
--
-- Optional: set COMMONLIB_PREBUILT=1 to let NG fetch its prebuilt release
-- bundle instead of compiling from source (see lib/commonlibsse-ng/xmake.lua).

set_xmakever("3.0.0")

set_version("3.3.5") -- the DLL's version resource + SKSEPluginInfo version (see CLAUDE.md, Bumping the Version)
set_license("Apache-2.0")

-- Root-scope settings from the included CommonLibSSE-NG xmake.lua apply only to
-- ITS targets -- the language standard must be declared here for ours.
set_arch("x64")
set_languages("c++23")
set_encodings("utf-8")

add_rules("mode.debug", "mode.release")

-- Reproducible package versions (xmake-requires.lock), as in AudioUtil.
set_policy("package.requires_lock", true)

-- Static CRT + release scheme mirrors AudioUtil's proven setup against the
-- same CommonLibSSE-NG v7 submodule. (Note: releases up to 3.3.4 used the
-- dynamic CRT via vcpkg; MT makes the DLL self-contained.)
if is_mode("debug") then
    add_defines("DEBUG")
    set_optimize("none")
    set_runtimes("MTd")
else
    add_defines("NDEBUG")
    set_optimize("fastest")
    set_symbols("debug") -- keep a PDB next to the optimized DLL
    set_runtimes("MT")
    set_policy("build.optimization.lto", true)
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
    -- real exports. The header defaults to NO storage class so consumers can copy
    -- and include it without their own plugin re-exporting (or link-depending on)
    -- our symbols -- only this build exports.
    add_defines("SLA_BUILDING_DLL", "WIN32_LEAN_AND_MEAN", "NOMINMAX", "UNICODE", "_UNICODE")

    -- Deploy ONLY the DLL to the shippable mod tree.
    after_build(function(target)
        local dist = path.join(os.projectdir(), "dist", "Core", "SKSE", "Plugins")
        os.mkdir(dist)
        os.cp(target:targetfile(), dist)
    end)
end)
