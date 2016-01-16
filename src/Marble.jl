module Marble

export
    # Types
    MarbleEnv,
    # Functions
    parse, process, render, template, build

include

# Markdown becoming Latex
using SettingsBundles
using JinjaTemplates
using Formatting
using YAML
using JSON

include("build_chain.jl") # Main application logic
include("flavor/Marble_MD.jl") # Custom MD flavor
include("render.jl") # Wrpper around Jinja2
include("util.jl") # Utility functions

end # module
