module DFVisualize
	using Reexport
	using InlineExports
	@reexport using DFControl
	const DFC = DFControl

	using Glimpse
	const Gl = Glimpse


	gray(f) = RGBAf0(f, f, f, 1.0)

	#new systems
	import Glimpse: System, SystemData, update, PointLight, Camera3D, Spatial, valid_entities, translmat, ModelMat, component, Point3f0, Diorama

	struct LightMover <: System
		data ::SystemData

		LightMover(dio::Diorama) = new(SystemData(dio, (PointLight, Camera3D, Spatial, ModelMat),()))
	end

	function update(sys::LightMover)
		comp(T) = component(sys, T)
		spat = comp(Spatial)
		cam  = comp(Camera3D)
		cam_e   = valid_entities(cam, spat)[1]
		light_e = valid_entities(comp(PointLight), spat)[1]
		spat[light_e]  = spat[cam_e]
	end

	function add_atom!(dio::Diorama, at::DFC.AbstractAtom)
		at_radius = Float32(sqrt(at.element.Z))/10
		Gl.add_entity!(dio, separate=[Gl.Spatial(position=at.position, velocity=zero(Gl.Vec3f0)),
		                              Gl.PolygonGeometry(Gl.Sphere(zero(Gl.Point3f0), 1.0f0)),
		                              Gl.UniformColor(RGBAf0(at.element.color..., 1.0f0)),
		                              Gl.Shape(at_radius),
		                              Gl.Material(),
		                              Gl.ProgramTag{Gl.DefaultProgram}(),
		                              Gl.Text(str= "$(at.name)", offset=Vec3f0(-at_radius, 0.0,0.0))])

    end

    function add_cell!(dio::Diorama, cell::Mat3)

		cellpoints = (cell',) .* [zero(Point3f0), zero(Point3f0), Point3f0(1, 0, 0),
		                          Point3f0(1, 1, 0), Point3f0(0, 1, 0), zero(Point3f0),
		                          Point3f0(0, 0, 1), Point3f0(1,0,1), Point3f0(1, 1, 1),
		                          Point3f0(0, 1, 1), Point3f0(0, 0, 1), Point3f0(0,0,0),
		                          Point3f0(1,0,0), Point3f0(1,0,1), Point3f0(1, 1, 1),
		                          Point3f0(1, 1, 0), Point3f0(0,1,0), Point3f0(0, 1, 1), Point3f0(0,1,1)]

		Gl.add_entity!(dio, separate=[Gl.ProgramTag{Gl.LineProgram}(),
		                              Gl.BufferColor([RGBAf0(0.0,0.0,0.0,1.0) for i = 1:length(cellpoints)]),
		                              Gl.Spatial(),
		                              Gl.Line(2f0, 0.6f0),
		                              Gl.VectorGeometry(cellpoints)])
    end
	@export function render_structure(str::DFC.AbstractStructure)
		dio = Diorama(background=gray(0.8))

		Gl.insert_system_after!(dio, Gl.CameraOperator, LightMover(dio))

		add_atom!.((dio,), atoms(str))
		add_cell!(dio, cell(str))

		Gl.update_system_indices!(dio)
		dio.loop = @async Gl.renderloop(dio)
		return dio
	end


end # module
