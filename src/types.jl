Base.convert(::Type{Point3f0},x::Point3D) = Point3f0(x.x,x.y,x.z)
Base.convert(::Type{Vec3f0},x::Point3D) = Vec3f0(x.x,x.y,x.z)



immutable GLContext
    context
end