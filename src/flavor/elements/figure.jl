using YAML

type Figure
    label::AbstractString
    path::AbstractString
    caption::Markdown.MD # This will be a parsable string
end

function Figure(input::Dict{Any,Any})
    label = get(input, "label", "")
    path = get(input, "path", "")
    caption = Markdown.parse(get(input, "caption", ""))
    return Figure(label, path, caption)
end

# Parser function
Markdown.@breaking true ->
function figure(stream::IO, md::Markdown.MD)
    Markdown.withstream(stream) do
        # Check to see if we start with the magic string
        # Avoid regex for "speed". I don't know.
        Markdown.startswith(stream, "Figure:", padding=true) || Markdown.startswith(stream, "figure:", padding=true) || return false

        # Now make sure there is nothing following figure tag
        if strip(readline(stream)) != ""
            return false
        end

        # Now finish the run
        buffer = IOBuffer()
        while !eof(stream)
            line_start = position(stream)

            if rstrip(readline(stream)) == "end"
                content = YAML.load(seek(buffer, 0))
                element = Figure(content)# Create the Figure
                push!(md, element)
                return true
            end
            seek(stream, line_start)
            write(buffer, readline(stream))
        end
        return false
    end
end 

function Markdown.latex(io::IOStream, fig::Figure)
    template = "Figure.template"

    caption_buffer = IOBuffer()
    Markdown.latex(caption_buffer, fig.caption)
    println(fig.caption)
    println(readall(caption_buffer))
    JinjaTemplate.write_from_template(io, template;
        path=fig.path,
        caption=readall(caption_buffer),
        label=fig.label
    )
end
