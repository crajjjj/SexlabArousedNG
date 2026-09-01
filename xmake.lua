-- Build for the SKSE plugin (xmake 3.0+, MSVC). CommonLibSSE-NG (alandtse fork,
-- pinned v7.0.0, Skyrim 1.7.99 capable) is vendored as a git submodule at
-- lib/commonlibsse-ng; its build deps (spdlog, directxtk, ...) come from
-- xmake-repo. Papyrus scripts are compiled separately (skyrimse.ppj / Pyro) --
-- this builds just the DLL.
--
--   xmake f -m releasedbg   # configure (first run compiles CommonLibSSE-NG)
--   xmake                   # build; DLL is deployed to dist/Core/SKSE/Plugins
--
-- Optional: set COMMONLIB_PREBUILT=1 to let NG fetch its prebuilt release
-- bundle instead of compiling from source (see lib/commonlibsse-ng/xmake.lua).

set_xmakever("3.0.0")

set_version("3.3.5") -- the DLL's version resource + SKSEPluginInfo version (see CLAUDE.md, Bumping the Version)
set_license("Apache-2.0")

add_rules("mode.debug", "mode.releasedbg")

-- Dynamic CRT: end users have the VC redist via Skyrim itself, and this keeps
-- the DLL small and consistent with previous releases.
if is_mode("debug") then
    set_runtimes("MDd")
else
    set_runtimes("MD")
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
