module CLIFramework

export CommandBundle, addcmd!, dispatch

type CommandBundle
    commands::Dict{AbstractString, Function}
    main::Function
    CommandBundle(f::Function) = new(Dict{AbstractArray, Function}(), f)
end

"""
Assign a function to a command (will be passed the remainter of ARGS
    as an argument)
"""
addcmd!(f::Function, cb::CommandBundle, key::AbstractString) = cb.commands[key] = f

function dispatch(cb::CommandBundle)
    if isempty(ARGS)
        cb.main(ARGS)
    elseif ARGS[1] in keys(cb.commands)
        cb.commands[ARGS[1]](ARGS[2:end])
    else
        cb.main(ARGS)
    end
end

end  # module CLIFramework