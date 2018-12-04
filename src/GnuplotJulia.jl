module GnuplotJulia

mutable struct Gnuplot
    io::Base.Process
    counter::Int
    padding::Int
    ext::String
    function Gnuplot()
        gp = new()
        gp.io = open(`gnuplot -p`, "w")
        print(gp.io, "set colorsequence podo;")
        gp.counter = 0 # File numbering. Useful when animating.
        gp.padding = 3 # File name padding, e.g., 009, 010.
        return gp
    end
end

# TODO: using variadic function causes overhead?
import Base: println
function println(gp::Gnuplot, x::T, y::T) where {T <:Real}
    println(gp.io, x, " ", y)
end
function println(gp::Gnuplot, x::T, y::T, z::T) where {T <:Real}
    println(gp.io, x, " ", y, " ", z)
end
function println(gp::Gnuplot, x::T, y::T, z::T, u::T) where {T <:Real}
    println(gp.io, x, " ", y, " ", z, " ", u)
end
function println(gp::Gnuplot,
                 x::T, y::T, z::T,
                 u::T, v::T) where {T <:Real}
    println(gp.io, x, " ", y, " ", z, " ", u, " ", v)
end
function println(gp::Gnuplot,
                 x::T, y::T, z::T,
                 u::T, v::T, w::T) where {T <:Real}
    println(gp.io, x, " ", y, " ", z, " ", u, " ", v, " ", w)
end

function tex(gp, x::Int, y::Int, opts::String = "")
    gp.ext = ".tex"
    println(gp.io, "
            reset;
            set terminal epslatex standalone size $(x)cm, $(y)cm\\
            color background 'white'\\
            header '\\usepackage[utf8]{inputenc} \\usepackage{amsmath}';
            set colorsequence podo;
            ", opts)
end

function png(gp, x::Int, y::Int, opts::String = "")
    gp.ext = ".png"
    println(gp.io, "
            reset;
            set terminal png enhanced nocrop font 'verdana, 8' size $x, $y;
            set colorsequence podo;
            ", opts)
end

macro plot(opts::String, ex::Expr)
    quote
        println(gp.io, "\$x$(gp.counter) << EOD")
        $(esc(ex))
        println(gp.io, "EOD")
        println(gp.io, "plot \$x$(gp.counter) ", $opts)
        println(gp.io, "e")
        gp.counter += 1
    end
end
macro replot(opts::String, ex::Expr)
    quote
        println(gp.io, "\$x$(gp.counter) << EOD")
        $(esc(ex))
        println(gp.io, "EOD")
        println(gp.io, "replot \$x$(gp.counter) ", $opts)
        println(gp.io, "e")
        gp.counter += 1
    end
end

#macro plot(opts::String, ex::Expr)
#    quote
#        println(gp.io, "set output 'tmp-",
#                lpad(gp.counter, gp.padding, '0'), gp.ext, "'")
#        println(gp.io, "\$tmp << EOD")
#        $(esc(ex))
#        println(gp.io, "EOD")
#        println(gp.io, "plot \$tmp ", opts)
#        println(gp.io, "e")
#        gp.counter += 1
#    end
#end
#
#macro plot!(opts::String, ex::Expr)
#    quote
#        println(gp.io, "set output 'tmp-",
#                lpad(gp.counter, gp.padding, '0'), gp.ext, "'")
#        println(gp.io, "replot ", opts)
#        println(gp.io, "$id << EOD")
#        $(esc(ex))
#        println(gp.io, "EOD")
#        println(gp.io, "e")
#        gp.counter += 1
#    end
#end

function tex2pdf()
    println(gp.io, "set output")
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
    println(gp.io, "set output")
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
    close(gp.io)
    wait(gp.io.closenotify)
    gp.counter = 0
end

gp = Gnuplot()
@plot "with circles" begin
    println(gp, 1,2,3)
end
@replot "with circles" begin
    println(gp, 1,2,2)
end

end #module
