using DFVisualize
using TraceCalls
using GLVisualize,GLWindow,GeometryTypes,ColorTypes
using JLD
T = Float32
# x = WannierModel{T}("/home/ponet/Documents/PhD/GeTe/NSOC/paperxsf/","/home/ponet/Documents/PhD/GeTe/SOC/GeTe_bands.out",[[PhysAtom(T[0.0,0.0,-0.0239129,-0.155854]...) for i=1:4]...,[PhysAtom(T[0.0,0.0,5.5540692,0.318205]...) for i=1:4]...]);
test_wfc1 =  read_xsf_file("/home/ponet/Documents/PhD/GeTe/NSOC/paperxsf/wan_00003.xsf", PhysAtom{T}(0.0, 0.0, 0.1, 0.1), T)
vertices_pos, vertices_neg = DFVisualize.marching_cubes(test_wfc1, 0.1)
using FileIO
test = load("/home/ponet/.julia/v0.6/DFVisualize/assets/renderables/cat.obj")
head = HMesh(Pyramid(Point3f0(0.5),0.5f0,0.25f0))
window = glscreen()
@code_warntype create_vector(Point3f0(0.0),Point3f0(0.0,0.0,5),RGBA(1.0f0,0.0f0,0.0f0,1.0f0),arrow_width=0.2f0)
_view(create_vector(Point3f0(0.0),Point3f0(0.0,0.0,5),RGBA(1.0f0,0.0f0,0.0f0,1.0f0),arrow_width=0.2),window)
renderloop(window)

