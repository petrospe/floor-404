"""Build the Floor 404 office kit and export glTF for Godot.

Mesh coordinates are authored in Godot meters (X right, Y up, Z forward)
and stored in Blender's Z-up space so the glTF export lands on the same axes.
"""

import os

import bmesh
import bpy
from mathutils import Vector


ROOT = r"C:\projects\floor-404"
TEX_DIR = os.path.join(ROOT, "assets_src", "textures")
BLEND_PATH = os.path.join(ROOT, "assets_src", "blender", "office_kit.blend")
EXPORT_DIR = os.path.join(ROOT, "godot_project", "models", "office")


def g2b(x, y, z):
    return (x, -z, y)


def b2g(co):
    return (co.x, co.z, -co.y)


def load_image(filename):
    path = os.path.join(TEX_DIR, filename)
    image = bpy.data.images.load(path, check_existing=True)
    image.pack()
    image.colorspace_settings.name = "sRGB"
    return image


def make_material(name, roughness, metallic=0.0, image=None, emission=None, emission_strength=0.0):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if image is not None:
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = image
        tex.interpolation = "Smart"
        tex.extension = "REPEAT"
        tex.location = (-360, 200)
        links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if emission_strength > 0.0:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
        if image is None:
            bsdf.inputs["Base Color"].default_value = (*emission, 1.0)
    return material


def add_box(bm, uv_layer, lo, hi, material_index):
    corners = [Vector(g2b(x, y, z)) for x in (lo[0], hi[0]) for y in (lo[1], hi[1]) for z in (lo[2], hi[2])]
    bmin = Vector((min(c.x for c in corners), min(c.y for c in corners), min(c.z for c in corners)))
    bmax = Vector((max(c.x for c in corners), max(c.y for c in corners), max(c.z for c in corners)))
    size = bmax - bmin
    if size.x < 1e-6 or size.y < 1e-6 or size.z < 1e-6:
        return
    geom = bmesh.ops.create_cube(bm, size=1.0)
    center = (bmin + bmax) * 0.5
    for vert in geom["verts"]:
        vert.co.x = vert.co.x * size.x + center.x
        vert.co.y = vert.co.y * size.y + center.y
        vert.co.z = vert.co.z * size.z + center.z
    faces = {face for vert in geom["verts"] for face in vert.link_faces}
    for face in faces:
        face.material_index = material_index
        face.smooth = False
    bmesh.ops.recalc_face_normals(bm, faces=list(faces))
    for face in faces:
        normal = face.normal
        godot_normal = Vector((normal.x, normal.z, -normal.y))
        axes = (abs(godot_normal.x), abs(godot_normal.y), abs(godot_normal.z))
        for loop in face.loops:
            gx, gy, gz = b2g(loop.vert.co)
            if axes[1] >= axes[0] and axes[1] >= axes[2]:
                loop[uv_layer].uv = (gx, gz)
            elif axes[0] >= axes[2]:
                loop[uv_layer].uv = (gz, gy)
            else:
                loop[uv_layer].uv = (gx, gy)


def new_mesh(name, build, materials):
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")
    build(bm, uv_layer)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for material in materials:
        mesh.materials.append(material)
    return obj


def godot_bounds(obj):
    xs, ys, zs = [], [], []
    for vert in obj.data.vertices:
        world = obj.matrix_world @ vert.co
        gx, gy, gz = b2g(world)
        xs.append(gx)
        ys.append(gy)
        zs.append(gz)
    return {
        "min": [round(min(xs), 4), round(min(ys), 4), round(min(zs), 4)],
        "max": [round(max(xs), 4), round(max(ys), 4), round(max(zs), 4)],
    }


def export_object(obj, filename):
    path = os.path.join(EXPORT_DIR, filename)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    kwargs = {
        "filepath": path,
        "export_format": "GLB",
        "use_selection": True,
        "export_apply": True,
    }
    props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
    if "export_yup" in props:
        kwargs["export_yup"] = True
    bpy.ops.export_scene.gltf(**kwargs)
    return path


def build_carpet(bm, uv):
    add_box(bm, uv, (0.0, -0.2, 0.0), (4.0, 0.0, 4.0), 0)


def build_ceiling(bm, uv):
    step = 0.5
    bar = 0.018
    for i in range(8):
        for j in range(8):
            x0 = i * step + bar
            z0 = j * step + bar
            add_box(bm, uv, (x0, 2.975, z0), (x0 + step - bar * 2, 3.02, z0 + step - bar * 2), 0)
    for i in range(9):
        pos = i * step
        add_box(bm, uv, (0.0, 3.02, pos - bar * 0.5), (4.0, 3.08, pos + bar * 0.5), 1)
        add_box(bm, uv, (pos - bar * 0.5, 3.02, 0.0), (pos + bar * 0.5, 3.08, 4.0), 1)


def build_wall(bm, uv):
    add_box(bm, uv, (0.0, 0.0, -0.06), (4.0, 3.0, 0.06), 0)
    add_box(bm, uv, (0.0, 0.0, -0.1), (4.0, 0.14, 0.1), 1)
    add_box(bm, uv, (0.0, 0.96, -0.085), (4.0, 1.02, 0.085), 1)


def build_window(bm, uv):
    add_box(bm, uv, (0.0, 0.0, -0.08), (0.7, 3.0, 0.08), 0)
    add_box(bm, uv, (3.3, 0.0, -0.08), (4.0, 3.0, 0.08), 0)
    add_box(bm, uv, (0.7, 0.0, -0.08), (3.3, 0.9, 0.08), 0)
    add_box(bm, uv, (0.7, 2.55, -0.08), (3.3, 3.0, 0.08), 0)
    add_box(bm, uv, (0.7, 0.9, -0.04), (3.3, 2.55, 0.04), 2)
    add_box(bm, uv, (1.98, 0.9, -0.05), (2.04, 2.55, 0.05), 1)
    add_box(bm, uv, (0.7, 1.7, -0.05), (3.3, 1.76, 0.05), 1)
    add_box(bm, uv, (0.0, 0.0, -0.1), (4.0, 0.12, 0.1), 1)


def build_door_frame(bm, uv):
    add_box(bm, uv, (0.0, 0.0, -0.08), (1.38, 3.0, 0.08), 0)
    add_box(bm, uv, (2.62, 0.0, -0.08), (4.0, 3.0, 0.08), 0)
    add_box(bm, uv, (1.38, 2.42, -0.08), (2.62, 3.0, 0.08), 0)
    add_box(bm, uv, (1.28, 0.0, -0.12), (1.4, 2.48, 0.12), 1)
    add_box(bm, uv, (2.6, 0.0, -0.12), (2.72, 2.48, 0.12), 1)
    add_box(bm, uv, (1.28, 2.36, -0.12), (2.72, 2.5, 0.12), 1)


def build_door_leaf(bm, uv):
    add_box(bm, uv, (0.02, 0.02, -0.02), (1.1, 2.32, 0.02), 0)
    add_box(bm, uv, (0.12, 1.25, -0.028), (1.0, 2.18, 0.028), 0)
    add_box(bm, uv, (0.12, 0.16, -0.028), (1.0, 1.12, 0.028), 0)
    add_box(bm, uv, (0.96, 0.98, 0.02), (1.06, 1.08, 0.06), 1)


def build_light(bm, uv):
    add_box(bm, uv, (-0.62, -0.01, -0.32), (0.62, 0.045, 0.32), 0)
    add_box(bm, uv, (-0.56, -0.02, -0.26), (0.56, -0.005, 0.26), 1)


def build_cubicle(bm, uv):
    add_box(bm, uv, (-0.925, 0.12, -0.025), (0.925, 1.4, 0.025), 0)
    add_box(bm, uv, (-0.925, 0.0, -0.03), (0.925, 0.12, 0.03), 1)
    add_box(bm, uv, (-0.925, 0.12, 0.0), (-0.875, 1.4, 1.5), 0)
    add_box(bm, uv, (0.875, 0.12, 0.0), (0.925, 1.4, 1.5), 0)
    add_box(bm, uv, (-0.7, 0.72, 0.18), (0.7, 0.76, 0.85), 2)


def build_column(bm, uv):
    add_box(bm, uv, (-0.34, 0.0, -0.34), (0.34, 3.0, 0.34), 0)
    add_box(bm, uv, (-0.4, 0.0, -0.4), (0.4, 0.12, 0.4), 1)


def build_table(bm, uv):
    add_box(bm, uv, (-0.85, 0.74, -0.375), (0.85, 0.79, 0.375), 0)
    for x in (-0.75, 0.75):
        for z in (-0.3, 0.3):
            add_box(bm, uv, (x - 0.025, 0.0, z - 0.025), (x + 0.025, 0.74, z + 0.025), 1)


def build_chair(bm, uv):
    add_box(bm, uv, (-0.24, 0.46, -0.24), (0.24, 0.52, 0.24), 0)
    add_box(bm, uv, (-0.24, 0.52, -0.24), (0.24, 1.15, -0.19), 0)
    add_box(bm, uv, (-0.03, 0.0, -0.03), (0.03, 0.46, 0.03), 1)


def prepare_scene():
    for obj in list(bpy.data.objects):
        if obj.type != "CAMERA":
            bpy.data.objects.remove(obj, do_unlink=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    if scene.world is None:
        scene.world = bpy.data.worlds.new("World")
    scene.world.color = (0.05, 0.05, 0.055)


def frame_view():
    for area in bpy.context.screen.areas:
        if area.type != "VIEW_3D":
            continue
        space = area.spaces[0]
        space.shading.type = "MATERIAL"
        space.clip_end = 1000.0
        region = next(region for region in area.regions if region.type == "WINDOW")
        with bpy.context.temp_override(area=area, region=region):
            bpy.ops.view3d.view_all()
        break


def build():
    os.makedirs(EXPORT_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(BLEND_PATH), exist_ok=True)
    prepare_scene()

    wall_img = load_image("wall.png")
    carpet_img = load_image("carpet.png")
    ceiling_img = load_image("ceiling.png")
    wood_img = load_image("wood.png")
    fabric_img = load_image("fabric.png")

    carpet_mat = make_material("Carpet", 0.95, image=carpet_img)
    ceiling_mat = make_material("CeilingTile", 0.88, image=ceiling_img)
    grid_mat = make_material("CeilingGrid", 0.45, 0.35)
    grid_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.22, 0.22, 0.21, 1.0)
    wall_mat = make_material("WallPaint", 0.82, image=wall_img)
    trim_mat = make_material("Trim", 0.55, 0.15)
    trim_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.32, 0.30, 0.27, 1.0)
    wood_mat = make_material("Wood", 0.55, image=wood_img)
    metal_mat = make_material("Metal", 0.32, 0.75)
    metal_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.55, 0.56, 0.58, 1.0)
    glass_mat = make_material("NightGlass", 0.06, 0.25)
    glass_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.02, 0.07, 0.06, 1.0)
    lamp_mat = make_material("Diffuser", 0.4, emission=(0.85, 0.93, 0.78), emission_strength=8.0)
    fabric_mat = make_material("CubicleFabric", 0.85, image=fabric_img)

    specs = [
        ("Carpet4x4", "carpet_4x4.glb", build_carpet, [carpet_mat]),
        ("Ceiling4x4", "ceiling_4x4.glb", build_ceiling, [ceiling_mat, grid_mat]),
        ("Wall4x3", "wall_4x3.glb", build_wall, [wall_mat, trim_mat]),
        ("WindowWall", "window_wall.glb", build_window, [wall_mat, trim_mat, glass_mat]),
        ("DoorFrame", "door_frame.glb", build_door_frame, [wall_mat, trim_mat]),
        ("DoorLeaf", "door_leaf.glb", build_door_leaf, [wood_mat, metal_mat]),
        ("LightPanel", "light_panel.glb", build_light, [metal_mat, lamp_mat]),
        ("Cubicle", "cubicle.glb", build_cubicle, [fabric_mat, metal_mat, wood_mat]),
        ("Column", "column.glb", build_column, [wall_mat, trim_mat]),
        ("Table", "table.glb", build_table, [wood_mat, metal_mat]),
        ("Chair", "chair.glb", build_chair, [fabric_mat, metal_mat]),
    ]

    exported = []
    objects = []
    for name, filename, builder, materials in specs:
        obj = new_mesh(name, builder, materials)
        bounds = godot_bounds(obj)
        path = export_object(obj, filename)
        exported.append({"name": name, "file": path, "godot_bounds": bounds})
        objects.append(obj)

    for index, obj in enumerate(objects):
        obj.location.x = index * 8.0

    bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
    frame_view()
    return {"blend": BLEND_PATH, "exported": exported}


result = build()
