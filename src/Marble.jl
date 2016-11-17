module Marble
# Markdown becoming Latex

export
    # Types
    MarbleEnv,
    # Document prep functions
    prepair, parse, process, render, template, build, changed, cache, save,
    # General use functions
    build_stream, build_file, build_dir, init_dir, print_settings

# External Packages
using Formatting
using FileState
using JinjaTemplates
using JSON
using SettingsBundles
using SHA
using YAML

# Internal Modules
# include("flavor/Marble_MD.jl")
# using MarbleFlavor

include("MarbleDoc.jl")
include("MarbleEnv.jl")
include("flavor/Marble_MD.jl") # Custom MD flavor
include("render.jl") # Wrapper around Jinja2
include("util.jl") # Utility functions
include("buildchain.jl") # Main application logic

end # module

