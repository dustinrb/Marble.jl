"""
Loads in a specified YAML file if it exists. Otherwise, it fails gracefully
"""
function load_conf_file!(path)
    if isfile(path)
        if extension(path) in ["yaml", "yml"]
            return SettingsYAMLFile(path)
        elseif extension(path) in ["json"]
            return SettingsJSONFile(path)
        else
            error("Marble does not know how to handle settings files of type \"$(extension(path))\"")
        end
    else
        warn("Configuration file `$path` not found. Continuing without it 🙁")
    end
    return env
end

"""
Builds a document given a specified Marble object
"""
function run_build_loop(env::MarbleEnv)
    # Maybe in the future, allow for drop in replacements based on
    # the evironment. For now, just run the standard loop.
    parse(env)
    process(env)
    render(env)
    template(env)
    build(env)
end

"""
Takes a given filename and returns its extension
"""
function extension(path)
    return split(path, '.')[end]
end
