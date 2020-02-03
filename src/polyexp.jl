using Polynomials
import Base: show, *, +

"""
    PolyExp(p::Vector{T}, a::T, b::T)
    PolyExp(pol::Poly{T},a::T,b::T)

On the model of `Poly` from package `Polynomials`, construct a function that is a polynome multiply by an exponential
function. The exponential is an exponential of an affine function ``a x + b``.
The polynome is construct from its coefficients `p`, lowest order first.

If ``f = (p_n x^n + \\ldots + p_2 x^2 + p_1 x + p_0)e^{a x + b}``, we construct this through
`PolyExp([a_0, a_1, ..., a_n], a, b)`. 
It is also possible to construct it directly from the polynome.

In the sequels some methods with the same name than for Poly are implemented (`polyder`,
`polyint`, `strings`, ...) but not all, only the methods needed are developped.

# Arguments :
- `p::Vector{T}` or pol::Poly{T} : vector of coefficients of the polynome, or directly the polynome.
- `a::T`, `b::T` : coefficients of affine exponentiated function.

# Examples
```julia
julia> pe=PolyExp([1,2,3],2,1)
PolyExp(Poly(1 + 2*x + 3*x^2)*exp(2*x + 1))

julia> pe(0)
2.718281828459045

julia> pe(1)
120.51322153912601
```
"""
struct PolyExp{T}
    p::Poly{T}
    a::T
    b::T
    PolyExp(p::Vector{T},a::T,b::T) where{T<:Number}=new{T}(Poly{T}(p), a, b)
    PolyExp(pol::Poly{T},a::T,b::T) where{T<:Number}=PolyExp(Polynomials.coeffs(pol), a, b)
end
function _printNumberPar(x::Number) 
    return isreal(x) ? "$(real(x))" : (iszero(real(x)) ? "$(imag(x))im" : "($x)")
end
function _printNumber(x::Number)
    return isreal(x) ? "$(real(x))" : (iszero(real(x)) ? "$(imag(x))im" : "$x")
end
function Base.show(io::IO, pe::PolyExp)
    return print(
    io, 
    "PolyExp($(pe.p)*exp($(_printNumberPar(pe.a))*x + $(_printNumber(pe.b))))"
)
end
"""
    polyder(pe::PolyExp)

Construct the derivative of the `pe` function.

# Examples
```julia
julia> polyder(PolyExp([1, 3, -1],3,1))
PolyExp(Poly(6 + 7*x - 3*x^2)*exp(3*x + 1))

julia> polyder(PolyExp([1.0+im, 3im, -1, 4.0], 2.0+1.5im,1.0im))
PolyExp(Poly((0.5 + 6.5im) - (6.5 - 6.0im)*x + (10.0 - 1.5im)*x^2 + (8.0 + 6.0im)*x^3)*exp((2.0 + 1.5im)*x + 1.0im))
```
"""
function Polynomials.polyder(pe::PolyExp)
    return PolyExp(pe.p*pe.a + Polynomials.polyder(pe.p), pe.a, pe.b)
end

"""
    polyint(pe::PolyExp)

Construct the integrate function of `pe` which is of `PolyExp` type.
The algorithm used is a recursive integration by parts.

# Examples
```julia
julia> polyint(PolyExp([1.0,2,3],2.0,5.0))
PolyExp(Poly(0.75 - 0.5*x + 1.5*x^2)*exp(2.0*x + 5.0))

julia> polyint(PolyExp([1.0+0im,2],2.0im,3.0+0im))
PolyExp(Poly((0.5 - 0.5im) - 1.0im*x)*exp(2.0im*x + 3.0))
```
"""
function polyint(pe::PolyExp)
    if ( pe.a != 0 )
        pol = pe.p / pe.a
        if Polynomials.degree(pe.p) > 0
            pol -= polyint(PolyExp(Polynomials.polyder(pe.p), pe.a, pe.b)).p / pe.a
        end
    else
        pol = Polynomials.polyint(pol)
    end
    return PolyExp( pol, pe.a, pe.b)
end
polyval(pe::PolyExp, v::AbstractArray) = map(x->polyval(pe, x), v)
polyval(pe::PolyExp, x::Number) = pe.p(x) * exp(pe.a*x + pe.b)
(pe::PolyExp)(x) = polyval(pe, x)
coeffs(pe::PolyExp) = vcat(Polynomials.coeffs(pe.p), pe.a, pe.b)
function polyint(p::PolyExp, v_begin::Number, v_end::Number )
    pol = polyint(p)
    return pol(v_end)-pol(v_begin)
end
*( p1::PolyExp, p2::PolyExp )=PolyExp(p1.p*p2.p,p1.a+p2.a,p1.b+p2.b)
function +( p1::PolyExp, p2::PolyExp )
    @assert (p1.a == p2.a && p1.b == p2.b) "for adding exponents must be equal"
    return PolyExp(p1.p+p2.p,p1.a,p1.b)
end


