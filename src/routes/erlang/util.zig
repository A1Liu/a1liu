const std = @import("std");
const liu = @import("liu");
const erlang = @import("./erlang.zig");
const ty = erlang.ty;
const ext = erlang.ext;
const BBox = ty.BBox;

const Vec2 = liu.Vec2;
const KeyCode = liu.gamescreen.KeyCode;

pub const camera: *Camera = &camera_;
var camera_: Camera = .{};
pub const rows: [3]liu.gamescreen.KeyRow = .{
    .{
        .leftX = 5,
        .keys = &[_]KeyCode{
            .key_q,
            .key_w,
            .key_e,
            .key_r,
            .key_t,
            .key_y,
            .key_u,
            .key_i,
            .key_o,
            .key_p,
        },
    },
    .{
        .leftX = 11,
        .keys = &[_]KeyCode{
            .key_a,
            .key_s,
            .key_d,
            .key_f,
            .key_g,
            .key_h,
            .key_j,
            .key_k,
            .key_l,
            .semicolon,
        },
    },
    .{
        .leftX = 27,
        .keys = &[_]KeyCode{
            .key_z,
            .key_x,
            .key_c,
            .key_v,
            .key_b,
            .key_n,
            .key_m,
            .comma,
            .period,
            .slash,
        },
    },
};

pub fn moveCamera(pos: Vec2) void {
    camera.pos = pos - Vec2{ camera.width / 2, camera.height / 2 };
}

// multiple cameras at once? LOL you can addd a CameraC to ECS registry:
//
// const CameraC = struct {
//     world_to_pixel: f32 = 1,
// };
//
// Unclear how it would interact with setDims, especially if there's multiple
// cameras active

pub const Camera = struct {
    pos: Vec2 = Vec2{ 0, 0 },
    height: f32 = 30,
    width: f32 = 10,
    world_to_pixel: f32 = 1,

    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    pub fn setDims(self: *Self, pix_width: u32, pix_height: u32) void {
        self.world_to_pixel = @intToFloat(f32, pix_height) / self.height;
        self.width = @intToFloat(f32, pix_width) / self.world_to_pixel;
    }

    pub fn screenToWorldCoordinates(self: *const Self, pos: Vec2) Vec2 {
        const pos_translated = pos / @splat(2, self.world_to_pixel);
        const pos_camera = Vec2{ pos_translated[0], self.height - pos_translated[1] };

        return pos_camera + self.pos;
    }

    pub fn screenSpaceCoordinates(self: *const Self, pos: Vec2) Vec2 {
        const pos_camera = pos - self.pos;

        const pos_canvas = Vec2{
            pos_camera[0] * self.world_to_pixel,
            (self.height - pos_camera[1]) * self.world_to_pixel,
        };

        return pos_canvas;
    }

    pub fn getScreenBoundingBox(self: *const Self, bbox: BBox) BBox {
        const coords = self.screenSpaceCoordinates(bbox.pos);
        const screen_height = bbox.height * self.world_to_pixel;

        return BBox{
            .pos = Vec2{ coords[0], coords[1] - screen_height },
            .width = bbox.width * self.world_to_pixel,
            .height = screen_height,
        };
    }
};
