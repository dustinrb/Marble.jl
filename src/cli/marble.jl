#! /usr/local/bin/julia

using Marble
using SettingsBundles

srcpath = "$(Pkg.dir("Marble"))/src"
include("$(srcpath)/cli/util.jl")
include("$(srcpath)/cli/commands.jl")

# Because we lack a swtich statment or pattern matching...
function main()
    if length(ARGS) == 0
        make(pwd())
    elseif ARGS[1] == "init" && length(ARGS) == 2
        init_project(ARGS[2])
    end
end

# Run that darn script
main()
