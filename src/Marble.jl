module Marble

export
    # Types
    MarbleEnv,
    # Functions
    parse, process, render, template, build, changed, cache, save

# Markdown becoming Latex
using SettingsBundles
using JinjaTemplates
using Formatting
using SHA
using YAML
using JSON

include("cacheing.jl") # Maintains a list of active documents
include("build_chain.jl") # Main application logic
include("flavor/Marble_MD.jl") # Custom MD flavor
include("render.jl") # Wrpper around Jinja2
include("util.jl") # Utility functions

end # module

