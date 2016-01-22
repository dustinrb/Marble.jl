"Given a directory, watches for changes to the main document and rebuilds
the whole project when it's saved"
function make(path)

    println("Loading settings... ") # LOGGING
    dirname = split(path, '/')[end]
    env = MarbleEnv(
        load_conf_file!("$(Pkg.dir("Marble"))/src/defaults.yaml"), # Defaults
        load_conf_file!("$(ENV["HOME"])/.mrbl/settings.yaml"), # User settings
        Dict(
            "workdir" => path,
            "dirname" => dirname,
            "maindoc" => "$dirname.md",
        ),
        load_conf_file!("$path/settings.yaml") # Project Settings
    )
    # Now that we've bootstraped ourselves, let's get going
    println("Building... ") # LOGGIN
    run_build_loop(env)

    # And keept it persistant if that's what's desired
    if env.settings["watch"]
        println("Starting build loop. Press Ctl-c to stop.")
        while true
            filename, event = watch_file(env.settings["workdir"])

            if filename == env.settings["maindoc"] && event.changed
                println("Rebuilding... ")
                run_build_loop(env)
            end
        end
    end
end

"Creates a new MD project in a specified directory. Also runs git init."
function init_project(path)
    projectname = split(path, '/')[end]
    mkpath(path)
    run(`cp -r $(Pkg.dir("Marble"))/templates/project/ $path`)
    cd(path)
    run(`sh $(Pkg.dir("Marble"))/src/cli/init_scripts/init.sh`)
end
