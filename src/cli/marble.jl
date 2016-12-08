#! /usr/local/bin/julia
const srcpath = "$(Pkg.dir("Marble"))/src"

include("$srcpath/cli/cli_framework.jl")

using ArgParse
using CLIFramework
using Marble

"""
The baseic `mrbl` command.

    mrbl [options] [path]

Options:
    clean: whether to clean the latex build dir
    out <path>: what should the outfile be name (single file only)
    format <fmt>: Out format. Options are `tex` and `pdf`. `html` comming... eventually

Arguments:
    path: Which file or directory to build using marble
"""
commands = CommandBundle() do args
    s = ArgParseSettings()
    @add_arg_table s begin
        "--clean", "-c"
            help = "clean marble build dir befor building"
            action = :store_true
        "--out", "-o"
            help = "output name/path for finished file (single file only)"
            default = nothing
        "--format"
            help = "output format. `tex` or `pdf`. `html` comming... eventually"
            arg_type = Symbol
            default = :pdf
        "path"
            help = "File or directory to compile with Marble"
            default = pwd()
    end
    a = parse_args(args, s)
    path = ispath(a["path"]) ? a["path"] : error("$(a["path"]) is a not a valide path.")

    # Remove existing tex build files
    if a["clean"]
        Marble.clean_tex(path)
    end

    # Build appropriate file types
    if isdir(path)
        Marble.build_dir(path; fmt=a["format"], out=a["out"])
    else
        Marble.build_file(path; fmt=a["format"], out=a["out"])
    end
end

add!(commands, "init") do args
    if length(args[1])
        init_project(args[1])
    end
end

add!(commands, "stream") do args
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
