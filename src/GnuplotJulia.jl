module GnuplotJulia

export Gnuplot, tex!, png!, cmd!, pts!, tex2pdf, tex2png, mpeg, cleanup

p = open(`gnuplot -p`, "w")
counter = 0 # File numbering. Useful when animating.
padding = 3 # File name padding, e.g., 009, 010.
ext = ""

function tex!(x::Int, y::Int; opts::String = "")
    ext = ".tex"
    println(p, "
            reset;
            set terminal epslatex standalone size $(x)cm, $(y)cm\\
            color background 'white'\\
            header '\\usepackage[utf8]{inputenc} \\usepackage{amsmath}';
            set colorsequence podo;
            ", opts)
end

function png!(x::Int, y::Int; opts::String = "")
    ext = ".png"
    println(p, "
            reset;
            set terminal png enhanced nocrop font 'verdana, 8' size $x, $y;
            set colorsequence podo;
            ", opts)
end

macro plot(ex::Expr)
    quote
        println(p, "set output 'tmp-",
                lpad(counter, padding, '0'), ext, "'")
        $(esc(ex))
        println(p, "e")
        counter += 1
    end
end

@inline function cmd!(opts::String)
    println(p, opts)
end

@inline function pts!(x::T, y::T) where {T <: Real}
    println(p, x, " ", y)
end

@inline function pts!(x::T, y::T, z::T) where {T <: Real}
    println(p, x, " ", y, " ", z)
end

function tex2pdf()
    println(p, "set output")
    run(pipeline(`latexmk`, stdout=devnull))
    for i = 0:counter-1
        x::String = lpad(i, padding, '0')
        run(pipeline(`dvips tmp-$x.dvi`, stdout=devnull))
        run(pipeline(`gs -dBATCH -dSAFER -dNOPAUSE
                     -sDEVICE=pdfwrite -sOutputFile=output-$x.pdf
                     tmp-$x.ps`, stdout=devnull))
    end
    run(`find -x . -name tmp-\* -delete`)
    #display("application/pdf", read("output.pdf"))
end

function tex2png()
    println(p, "set output")
    run(pipeline(`latexmk`, stdout=devnull))
    for i = 0:counter-1
        x::String = lpad(i, padding, '0')
        run(pipeline(`dvips tmp-$x.dvi`, stdout=devnull))
        run(pipeline(`gs -dBATCH -dSAFER -dNOPAUSE
                     -sDEVICE=pngalpha -sOutputFile=output-$x.png
                     tmp-$x.ps`, stdout=devnull))
    end
    run(`find -x . -name tmp-\* -delete`)
    #display("image/png", read("output.png"))
end

function mpeg()
    run(pipeline(`ffmpeg -y -i output-%0$(padding)d.png output.mpeg`,
                 stdout=devnull, stderr=devnull))
    #display("text/html", """
    #        <video autoplay controls>
    #        <source src="output.mpeg" type="video/mpeg">
    #        </video>
    #        """)
end

function cleanup()
    close(p)
    wait(p.closenotify)
    counter = 0
end

end # module
