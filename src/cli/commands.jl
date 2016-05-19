"Given a directory, watches for changes to the main document and rebuilds
the whole project when it's saved"
function make(path)
    env = get_env(path)
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

"Runs build phase without parsing markdown to latex"
function make_tex(path)
    env = get_env(path)
    println("Building TeX file... ") # LOGGIN
    build(env)
end

"Creates a new MD project in a specified directory. Also runs git init."
function init_project(path)
    projectname = split(path, '/')[end]
    mkpath(path)
    run(`cp -r $(Pkg.dir("Marble"))/templates/project/ $path`)
    cd(path)
    run(`sh $(Pkg.dir("Marble"))/src/cli/init_scripts/init.sh`)
end
