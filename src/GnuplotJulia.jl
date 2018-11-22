module GnuplotJulia

export Gnuplot, tex!, png!, openPlot!, closePlot!, cmd!, plot!, tex2pdf,
tex2png, mpeg, cleanup

mutable struct Gnuplot
    p::Base.Process
    counter::Int
    padding::Int
    ext::String
    function Gnuplot()
        gp = new()
        gp.p = open(`gnuplot -p`, "w")
        print(gp.p, "set colorsequence podo;")
        gp.counter = 0 # File numbering. Useful when animating.
        gp.padding = 3 # File name padding, e.g., 009, 010.
        return gp
    end
end

function tex!(x::Int, y::Int; opts::String = "")
    gp.ext = ".tex"
    println(gp.p, "
            reset;
            set terminal epslatex standalone size $(x)cm, $(y)cm\\
            color background 'white'\\
            header '\\usepackage[utf8]{inputenc} \\usepackage{amsmath}';
            set colorsequence podo;
            ", opts)
end

function png!(x::Int, y::Int; opts::String = "")
    gp.ext = ".png"
    println(gp.p, "
            reset;
            set terminal png enhanced nocrop font 'verdana, 8' size $x, $y;
            set colorsequence podo;
            ", opts)
end

macro plot(ex::Expr)
    quote
        println(gp.p, "set output 'tmp-",
                lpad(gp.counter, gp.padding, '0'), gp.ext, "'")
        $(esc(ex))
        println(gp.p, "e")
        gp.counter += 1
    end
end

@inline function cmd!(opts::String)
    println(gp.p, opts)
end

@inline function pts!(x::T, y::T) where {T <: Real}
    println(gp.p, x, " ", y)
end

@inline function pts!(x::T, y::T, z::T) where {T <: Real}
    println(gp.p, x, " ", y, " ", z)
end

function tex2pdf()
    println(gp.p, "set output")
    run(pipeline(`latexmk`, stdout=devnull))
    for i = 0:gp.counter-1
        x::String = lpad(i, gp.padding, '0')
        run(pipeline(`dvips tmp-$x.dvi`, stdout=devnull))
        run(pipeline(`gs -dBATCH -dSAFER -dNOPAUSE
                     -sDEVICE=pdfwrite -sOutputFile=output-$x.pdf
                     tmp-$x.ps`, stdout=devnull))
    end
    run(`find -x . -name tmp-\* -delete`)
    #display("application/pdf", read("output.pdf"))
end

function tex2png()
    println(gp.p, "set output")
    run(pipeline(`latexmk`, stdout=devnull))
    for i = 0:gp.counter-1
        x::String = lpad(i, gp.padding, '0')
        run(pipeline(`dvips tmp-$x.dvi`, stdout=devnull))
        run(pipeline(`gs -dBATCH -dSAFER -dNOPAUSE
                     -sDEVICE=pngalpha -sOutputFile=output-$x.png
                     tmp-$x.ps`, stdout=devnull))
    end
    run(`find -x . -name tmp-\* -delete`)
    #display("image/png", read("output.png"))
end

function mpeg()
    run(pipeline(`ffmpeg -y -i output-%0$(gp.padding)d.png output.mpeg`,
                 stdout=devnull, stderr=devnull))
    #display("text/html", """
    #        <video autoplay controls>
    #        <source src="output.mpeg" type="video/mpeg">
    #        </video>
    #        """)
end

function cleanup()
    close(gp.p)
    wait(gp.p.closenotify)
    gp.counter = 0
end

global gp = Gnuplot()

end # module
