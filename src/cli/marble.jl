#! /usr/local/bin/julia
include("$(Pkg.dir("Marble"))/src/cli/cli_framework.jl")

using Marble
using CLIFramework
using SettingsBundles

srcpath = "$(Pkg.dir("Marble"))/src"
include("$(srcpath)/cli/util.jl")
include("$(srcpath)/cli/commands.jl")

commands = CommandBundle() do args
    # println("I havent gotten my act together")
    # exit()
    if length(args) == 0
        makepath(pwd())
    elseif isdir(args[1])
        makepath(args[1])
    elseif isfile(args[1])
        build_file(args[1])
    else
        println("$(args[1]) is a banna")
    end
end

addcmd!(commands, "init") do args
    if length(args[1])
        init_project(args[1])
    end
end

addcmd!(commands, "stream") do args
    error("Improperly implemented. Try later")
    exit()
    global STDOUT
    global STDIN

    # Do some magic in hopes of silencing println output
    sout = STDOUT
    STDOUT = IOBuffer()

    # Do the build
    build_stream(STDIN, sout; fmt=:tex)

    # Print out any error messages that happened
    seek(STDOUT, 0)
    println(sout, readstring(STDOUT))
end

# Run that darn script
dispatch(commands)
