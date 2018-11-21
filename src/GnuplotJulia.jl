module GnuplotJulia

const Data2D = NTuple{2, Vector{<:Real}}
const Data3D = NTuple{3, Vector{<:Real}}

mutable struct Gnuplot
    p::Base.Process
    counter::Int
    padding::Int
    ext::String
    function Gnuplot()
        p = open(`gnuplot`, "w")
        print(p, "set colorsequence podo;")
        return new(p, 0, 3)
    end
end

function epslatex!(gp::Gnuplot, x::Int, y::Int)
    gp.ext = ".tex"
    print(gp.p, "
          set terminal epslatex standalone size $(x)cm, $(y)cm\\
          color background 'white'\\
          header '\\usepackage[utf8]{inputenc} \\usepackage{amsmath}';
          ")
end

function png!(gp::Gnuplot, x::Int, y::Int)
    gp.ext = ".png"
    print(gp.p, "
          set terminal png enhanced nocrop font 'verdana, 8' size $x, $y;
          ")
end

function config!(gp::Gnuplot, opts::String)
    println(gp.p, opts)
end

function plot(gp::Gnuplot, data::Data2D, opts::String)
    x::Vector{<:Real} = data[1]
    y::Vector{<:Real} = data[2]
    n::Int = min(length(x), length(y))

    println(gp.p, "set output 'tmp-",
            lpad(gp.counter, gp.padding, '0'), gp.ext, "'")
    println(gp.p, "plot '-' ", opts)
    @inbounds for i = 1:n
        println(gp.p, x[i], " ", y[i])
    end
    println(gp.p, "e")
    gp.counter += 1
end

function tex2pdf(gp::Gnuplot)
    println(gp.p, "set output")
    run(pipeline(`latexmk`, stdout=devnull, stderr=devnull))
    for i = 0:gp.counter-1
        x::String = lpad(i, gp.padding, '0')
        run(pipeline(`dvips tmp-$x.dvi`, stdout=devnull, stderr=devnull))
        run(pipeline(`gs -dBATCH -dSAFER -dNOPAUSE
                     -sDEVICE=pdfwrite -sOutputFile=output-$x.pdf
                     tmp-$x.ps`, stdout=devnull, stderr=devnull))
    end
    #display("application/pdf", read("output.pdf"))
end

function tex2png(gp::Gnuplot)
    println(gp.p, "set output")
    run(pipeline(`latexmk`, stdout=devnull, stderr=devnull))
    for i = 0:gp.counter-1
        x::String = lpad(i, gp.padding, '0')
        run(pipeline(`dvips tmp-$x.dvi`, stdout=devnull, stderr=devnull))
        run(pipeline(`gs -dBATCH -dSAFER -dNOPAUSE
                     -sDEVICE=pngalpha -sOutputFile=output-$x.png
                     tmp-$x.ps`, stdout=devnull, stderr=devnull))
    end
    #display("image/png", read("output.png"))
end

function mpeg(gp::Gnuplot)
    run(pipeline(`ffmpeg -y -i output-%0$(gp.padding)d.png output.mpeg`,
                 stdout=devnull, stderr=devnull))
    #display("text/html", """
    #        <video autoplay controls>
    #        <source src="output.mpeg" type="video/mpeg">
    #        </video>
    #        """)
end

function cleanup(gp::Gnuplot)
    close(gp.p)
    wait(gp.p.closenotify)
    gp.counter = 0
    run(`find -x . -name tmp-\* -delete`)
end

end # module
