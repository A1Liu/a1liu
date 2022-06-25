const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

const NULL = std.math.maxInt(u32);

pub const EntityId = struct {
    index: u32,
    generation: u32,

    pub const NULL: EntityId = .{ .index = std.math.maxInt(u32), .generation = 0 };
};

fn FreeEnt(comptime T: type) type {
    return union { t: T, next: u32 };
}

const FieldInfo = struct {
    is_optional: bool,
    is_pointer: bool,
    T: type,
};

fn UnwrappedField(comptime FieldT: type) FieldInfo {
    const is_optional = @typeInfo(FieldT) == .Optional;
    const child = switch (@typeInfo(FieldT)) {
        .Optional => |info| info.child,
        else => FieldT,
    };

    const is_pointer = @typeInfo(child) == .Pointer;
    const T = switch (@typeInfo(child)) {
        .Pointer => |info| info.child,
        else => child,
    };

    return .{
        .is_optional = is_optional,
        .is_pointer = is_pointer,
        .T = T,
    };
}

fn RegistryView(comptime Reg: type, comptime InViewType: type) type {
    return struct {
        pub const ViewType = @Type(.{
            .Struct = .{
                .layout = .Auto,
                .decls = &.{},
                .is_tuple = false,
                .fields = std.meta.fields(InViewType) ++ [_]std.builtin.Type.StructField{
                    .{
                        .name = "id",
                        .field_type = EntityId,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = @alignOf(EntityId),
                    },
                    .{
                        .name = "name",
                        .field_type = []const u8,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = @alignOf([]const u8),
                    },
                },
            },
        });

        const Iter = @This();

        registry: *const Reg,
        index: u32 = 0,

        pub fn read(registry: *const Reg, index: u32) ?ViewType {
            const meta = &registry.raw(Reg.Meta)[index];

            var value: ViewType = undefined;
            value.id = .{ .index = index, .generation = meta.generation };
            value.name = registry.strings.get(meta.name) orelse {
                liu.wasm.post(.log, "wtf: {}", .{meta.name});
                unreachable;
            };

            inline for (std.meta.fields(ViewType)) |field| {
                if (comptime std.mem.eql(u8, field.name, "id")) continue;
                if (comptime std.mem.eql(u8, field.name, "name")) continue;

                const unwrapped = UnwrappedField(field.field_type);
                if (unwrapped.is_optional) continue;

                const Idx = comptime Reg.typeIndex(unwrapped.T) orelse
                    @compileError("field type not registered: " ++
                    "name=" ++ field.name ++ ", type=" ++ @typeName(unwrapped.T));

                const is_set = meta.bitset.isSet(Idx);
                if (!is_set) return null;

                const ptr = &registry.raw(unwrapped.T)[index];
                @field(value, field.name) = if (unwrapped.is_pointer) ptr else ptr.*;
            }

            inline for (std.meta.fields(ViewType)) |field| {
                if (comptime std.mem.eql(u8, field.name, "id")) continue;
                if (comptime std.mem.eql(u8, field.name, "meta")) continue;

                const unwrapped = UnwrappedField(field.field_type);
                if (!unwrapped.is_optional) continue;

                const Idx = comptime Reg.typeIndex(unwrapped.T) orelse
                    @compileError("field type not registered: " ++
                    "name=" ++ field.name ++ ", type=" ++ @typeName(unwrapped.T));

                const is_set = meta.bitset.isSet(Idx);
                @field(value, field.name) = value: {
                    if (!is_set) {
                        break :value null;
                    }

                    const ptr = &registry.raw(unwrapped.T)[index];
                    break :value if (unwrapped.is_pointer) ptr else ptr.*;
                };
            }

            return value;
        }

        pub fn get(self: *Iter, id: EntityId) ?ViewType {
            const index = self.registry.indexOf(id) orelse return null;

            return read(self.registry, index); //, &sparse);
        }

        pub fn reset(self: *Iter) void {
            self.index = 0;
        }

        pub fn next(self: *Iter) ?ViewType {
            while (self.index < self.registry.len) {
                // this enforces the index increment, even when the return
                // happens below
                defer self.index += 1;

                const meta = &self.registry.raw(Reg.Meta)[self.index];
                if (meta.generation == NULL) continue;

                const value = read(self.registry, self.index);
                if (value) |v| return v;
            }

            return null;
        }
    };
}

// TODO: creating entity during iteration
// TODO add back sparse (commented out code is wrong so rewrite it lol)

// comptime InSparse: []const type,
pub fn Registry(comptime InDense: []const type) type {
    comptime {
        // for (InSparse) |T| {
        //     if (@sizeOf(T) > 0) continue;

        //     @compileError("Zero-sized components should be Dense. Having them be " ++
        //         "Dense requires less runtime work, and also I didn't " ++
        //         "implement all the code for making them sparse. To be clear, " ++
        //         "there is no performance benefit to a component with size 0 " ++
        //         "being sparse instead of dense.");
        // }

        const InComponents = InDense;
        // const InComponents =  InSparse ++ InDense;
        for (InComponents) |T, idx| {
            // NOTE: for now, this code is a bit more verbose than necessary.
            // Unfortunately, doing `Components[0..idx]` below to filter
            // out all repeated instances causes a compiler bug.
            for (InComponents) |S, o_idx| {
                if (o_idx >= idx) break;
                if (T != S) continue;

                @compileError("The type '" ++ @typeName(T) ++ "' was registered " ++
                    "multiple times. Since components are queried by-type, " ++
                    "you can only have one of a component type for each entity.");
            }
        }
    }

    return struct {
        const Self = @This();

        const Components = DenseComponents;
        // const Components = SparseComponents ++ DenseComponents;
        const DenseComponents = InDense ++ [_]type{Meta};
        // const SparseComponents = InSparse;

        pub const Meta = struct {
            name: u32, // use this field to store the next freelist element
            generation: u32,
            bitset: std.StaticBitSet(Components.len - 1),
        };

        const List = std.ArrayListUnmanaged;
        // const Mapping = struct {
        //     // index is entity ID, value is component index
        //     map: std.ArrayListUnmanaged(u32) = .{},
        // };

        const DensePointers = [DenseComponents.len][*]u8;
        // const SparsePointers = [SparseComponents.len]List(u8);

        alloc: std.mem.Allocator,
        strings: liu.StringTable,
        generation: u32,

        dense: DensePointers,
        count: u32,
        len: u32,
        capacity: u32,
        free_head: u32,

        pub fn init(capacity: u32, alloc: std.mem.Allocator) !Self {
            var dense: DensePointers = undefined;
            inline for (DenseComponents) |T, Idx| {
                if (@sizeOf(T) == 0) continue;

                const slice = try alloc.alloc(T, capacity);
                dense[Idx] = @ptrCast([*]u8, slice.ptr);
            }

            return Self{
                .dense = dense,
                .count = 0,
                .len = 0,
                .generation = 1,
                .capacity = capacity,
                .strings = .{},
                .alloc = alloc,
                .free_head = NULL,
            };
        }

        pub fn deinit(self: *Self) void {
            self.strings.deinit(self.alloc);

            inline for (DenseComponents) |T, idx| {
                if (@sizeOf(T) == 0) continue;

                var slice: []T = &.{};
                slice.ptr = @ptrCast([*]T, @alignCast(@alignOf(T), self.dense[idx]));
                slice.len = self.capacity;

                self.alloc.free(slice);
            }
        }

        pub fn create(self: *Self, name: []const u8) !EntityId {
            self.count += 1;
            errdefer self.count -= 1;

            const index = index: {
                if (self.free_head != NULL) {
                    const index = self.free_head;
                    const meta = &self.raw(Meta)[self.free_head];
                    self.free_head = meta.name;

                    break :index index;
                }

                if (self.len >= self.capacity) {
                    const new_capa = self.capacity + self.capacity / 2;

                    inline for (DenseComponents) |T, idx| {
                        if (@sizeOf(T) == 0) continue;

                        var slice: []T = &.{};
                        slice.ptr = @ptrCast([*]T, @alignCast(@alignOf(T), self.dense[idx]));
                        slice.len = self.capacity;

                        const new_mem = try self.alloc.realloc(slice, new_capa);
                        self.dense[idx] = @ptrCast([*]u8, new_mem.ptr);
                    }

                    self.capacity = new_capa;
                }

                const index = self.len;
                self.len += 1;
                break :index index;
            };

            const name_id = try self.strings.add(self.alloc, name);
            errdefer self.strings.delete(name_id);

            const meta = &self.raw(Meta)[index];
            meta.name = name_id;
            meta.generation = self.generation;
            meta.bitset = std.StaticBitSet(Components.len - 1).initEmpty();

            return EntityId{ .index = index, .generation = self.generation };
        }

        pub fn delete(self: *Self, id: EntityId) bool {
            const index = self.indexOf(id) orelse return false;
            self.count -= 1;

            const meta = &self.raw(Meta)[index];
            self.strings.delete(meta.name);

            if (self.count == 0) {
                self.len = 0;
                self.free_head = NULL;

                // Should generation be reset here? Technically someone could
                // be holding an external entity ID which would then false-positive

                return true;
            }

            meta.generation = NULL;
            meta.name = self.free_head;

            self.free_head = id.index;
            self.generation += 1;

            return true;
        }

        pub fn addComponent(self: *Self, id: EntityId, component: anytype) !void {
            const T = @TypeOf(component);
            if (T == Meta) @compileError("Tried to add a Meta component");

            const index = self.indexOf(id) orelse return;

            const Idx = comptime typeIndex(T) orelse
                @compileError("Type not registered: " ++ @typeName(T));

            // we defer here so that we can read the previous value before
            // returning
            defer self.raw(Meta)[index].bitset.set(Idx);

            const elements = self.raw(T);
            elements[index] = component;

            return;
        }

        fn raw(self: *const Self, comptime T: type) []T {
            if (comptime denseTypeIndex(T)) |Idx| {
                var slice: []T = &.{};
                slice.len = self.len;

                if (@sizeOf(T) > 0) {
                    slice.ptr = @ptrCast([*]T, @alignCast(@alignOf(T), self.dense[Idx]));
                }

                return slice;
            }

            @compileError("Type not registered: " ++ @typeName(T));
        }

        pub fn view(self: *Self, comptime ViewType: type) RegistryView(Self, ViewType) {
            return .{ .registry = self };
        }

        fn indexOf(self: *const Self, id: EntityId) ?u32 {
            const meta_slice = self.raw(Meta);
            if (id.index >= meta_slice.len) return null;

            const meta = &meta_slice[id.index];
            if (meta.generation > id.generation) return null;

            return id.index;
        }

        fn typeIndex(comptime T: type) ?usize {
            for (Components) |Component, idx| {
                if (T == Component) return idx;
            }

            return null;
        }

        fn denseTypeIndex(comptime T: type) ?usize {
            for (DenseComponents) |Component, idx| {
                if (T == Component) return idx;
            }

            return null;
        }
    };
}

test "Registry: iterate" {
    const TransformComponent = struct { i: u32 };
    const MoveComponent = struct {};

    const RegistryType = Registry(&.{ TransformComponent, MoveComponent });

    var registry = try RegistryType.init(256, liu.Pages);
    defer registry.deinit();

    // var success = false;

    var i: u32 = 0;
    while (i < 257) : (i += 1) {
        const meh = try registry.create("meh");
        // success =
        try registry.addComponent(meh, TransformComponent{ .i = meh.index });
        // try std.testing.expect(success);
    }

    try std.testing.expect(registry.len == 257);
    try std.testing.expect(registry.capacity > 256);

    const View = struct {
        transform: ?TransformComponent,
        move: ?*MoveComponent,
    };

    var view = registry.view(View);
    while (view.next()) |elem| {
        try std.testing.expect(elem.name.len == 3);
        if (elem.transform) |t|
            try std.testing.expect(t.i == elem.id.index)
        else
            try std.testing.expect(false);

        try std.testing.expect(elem.move == null);
    }
}

test "Registry: delete" {
    const TransformComponent = struct {};
    const MoveComponent = struct {};

    const RegistryType = Registry(&.{ TransformComponent, MoveComponent });

    var registry = try RegistryType.init(256, liu.Pages);
    defer registry.deinit();

    const View = struct {
        transform: ?TransformComponent,
        move: ?*MoveComponent,
    };

    _ = try registry.create("meh");
    const deh = try registry.create("dehh");

    try std.testing.expect(registry.delete(deh));

    var view = registry.view(View);
    var count: u32 = 0;
    while (view.next()) |elem| {
        try std.testing.expect(elem.name.len == 3);
        count += 1;
    }

    try std.testing.expect(count == 1);

    view.reset();
}
