const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

pub const EntityId = struct {
    index: u32,
    generation: u32,

    pub const NULL: EntityId = .{ .index = std.math.maxInt(u32), .generation = 0 };
};

fn FreeEnt(comptime T: type) type {
    return union { t: T, next: u32 };
}

fn UnwrappedField(comptime FieldT: type) struct { isPointer: bool, T: type } {
    const child = switch (@typeInfo(FieldT)) {
        .Optional => |info| info.child,
        else => @compileError("Expected field to be optional, found '" ++
            @typeName(FieldT) ++ "'"),
    };

    const isPointer = @typeInfo(child) == .Pointer;
    const T = switch (@typeInfo(child)) {
        .Pointer => |info| info.child,
        else => child,
    };

    return .{ .isPointer = isPointer, .T = T };
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
                        .name = "meta",
                        .field_type = *const Reg.Meta,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = @alignOf(*const Reg.Meta),
                    },
                },
            },
        });

        const Iter = @This();

        registry: *Reg,
        index: u32 = 0,
        sparse: [Reg.SparseComponents.len]u32 = .{0} ** Reg.SparseComponents.len,

        // This is a separate function because there was some kind of confusing
        // compiler behavior otherwise.
        fn readForField(
            registry: *Reg,
            meta: *const Reg.Meta,
            out: *ViewType,
            comptime name: []const u8,
            comptime FieldT: type,
            index: u32,
            sparse: *[Reg.SparseComponents.len]u32,
        ) void {
            @field(out, name) = value: {
                const unwrapped = UnwrappedField(FieldT);
                const isPointer = unwrapped.isPointer;
                const T = unwrapped.T;

                const Idx = comptime Reg.typeIndex(T) orelse
                    @compileError("field type not registered: " ++
                    "name=" ++ name ++ ", type=" ++ @typeName(T));

                if (!meta.bitset.isSet(Idx)) {
                    break :value null;
                }

                if (comptime Reg.sparseTypeIndex(T)) |SparseIdx| {
                    const sparse_index = sparse[SparseIdx];
                    sparse[SparseIdx] += 1;

                    const ptr = &registry.rawSparse(T).items[sparse_index].t;
                    break :value if (isPointer) ptr else ptr.*;
                }

                const ptr = &registry.raw(T)[index];
                break :value if (isPointer) ptr else ptr.*;
            };
        }

        pub fn read(registry: *Reg, index: u32, sparse: *[Reg.SparseComponents.len]u32) ViewType {
            const meta = &registry.raw(Reg.Meta)[index];

            var value: ViewType = undefined;
            value.id = .{ .index = index, .generation = meta.generation };
            value.meta = meta;

            inline for (std.meta.fields(ViewType)) |field| {
                if (comptime std.mem.eql(u8, field.name, "id")) continue;
                if (comptime std.mem.eql(u8, field.name, "meta")) continue;

                readForField(registry, meta, &value, field.name, field.field_type, index, sparse);
            }

            return value;
        }

        pub fn get(self: *Iter, id: EntityId) ?ViewType {
            const index = self.registry.indexOf(id) orelse return null;

            var sparse: [Reg.SparseComponents.len]u32 = undefined;
            inline for (std.meta.fields(ViewType)) |field| {
                if (comptime std.mem.eql(u8, field.name, "id")) continue;
                if (comptime std.mem.eql(u8, field.name, "meta")) continue;

                const T = UnwrappedField(field.field_type).T;
                const SparseIdx = comptime Reg.sparseTypeIndex(T) orelse continue;
                const mapping = self.registry.sparse_mapping[SparseIdx];

                sparse[SparseIdx] = mapping.map.get(index) orelse 0;
            }

            return read(self.registry, index, &sparse);
        }

        pub fn reset(self: *Iter) void {
            self.index = 0;
            std.mem.set(u32, &self.sparse, 0);
        }

        pub fn next(self: *Iter) ?ViewType {
            while (self.index < self.registry.len) {
                // this enforces the index increment, even when the return
                // happens below
                defer self.index += 1;

                const meta = &self.registry.raw(Reg.Meta)[self.index];
                if (meta.generation == std.math.maxInt(u32)) continue;

                const value = read(self.registry, self.index, &self.sparse);
                return value;
            }

            return null;
        }
    };
}

pub fn Registry(
    comptime InDense: []const type,
    comptime InSparse: []const type,
) type {
    comptime {
        for (InSparse) |T| {
            if (@sizeOf(T) > 0) continue;

            @compileError(
                \\Zero-sized components should be Dense. Having them be Dense
                \\ requires less runtime work, and also I didn't implement all
                \\ the code for making them sparse. To be clear, there is no
                \\ performance benefit to a component with size 0 being sparse
                \\ instead of dense.
            );
        }

        const InComponents = InSparse ++ InDense;
        for (InComponents) |T, idx| {
            // NOTE: for now, this code does a bit more work than necessary.
            // Unfortunately, doing `Components[0..idx]` below to filter
            // out all repeated instances causes a compiler bug.
            for (InComponents) |S, o_idx| {
                if (idx == o_idx) continue;
                if (T != S) continue;

                @compileError("The type '" ++ @typeName(T) ++
                    \\' was registered multiple times. Since components are
                    \\ queried by-type, you can only have one of a component
                    \\ type for each entity.
                );
            }
        }
    }

    return struct {
        const Self = @This();

        const Components = SparseComponents ++ DenseComponents;
        const DenseComponents = InDense ++ [_]type{Meta};
        const SparseComponents = InSparse;

        pub const Meta = struct {
            name: []const u8, // use the len field to store the generation
            generation: u32,
            bitset: std.StaticBitSet(Components.len - 1),
        };

        const List = std.ArrayListUnmanaged;
        const Mapping = struct {
            free_head: u32 = std.math.maxInt(u32),
            map: std.AutoHashMapUnmanaged(u32, u32) = .{},
        };

        const DensePointers = [DenseComponents.len][*]u8;
        const SparsePointers = [SparseComponents.len]List(u8);

        alloc: std.mem.Allocator,
        generation: u32,

        dense: DensePointers,
        len: u32,
        capacity: u32,
        free_head: u32,

        sparse_mapping: [SparseComponents.len]Mapping,
        sparse: SparsePointers,

        pub fn init(capacity: u32, alloc: std.mem.Allocator) !Self {
            var dense: DensePointers = undefined;
            inline for (DenseComponents) |T, Idx| {
                if (@sizeOf(T) == 0) continue;

                const slice = try alloc.alloc(T, capacity);
                dense[Idx] = @ptrCast([*]u8, slice.ptr);
            }

            const sparse_mapping = .{Mapping{}} ** SparseComponents.len;
            const sparse: SparsePointers = .{.{}} ** SparseComponents.len;

            return Self{
                .dense = dense,
                .sparse_mapping = sparse_mapping,
                .sparse = sparse,
                .len = 0,
                .generation = 1,
                .capacity = capacity,
                .alloc = alloc,
                .free_head = std.math.maxInt(u32),
            };
        }

        pub fn deinit(self: *Self) void {
            inline for (DenseComponents) |T, idx| {
                if (@sizeOf(T) == 0) continue;

                var slice: []T = &.{};
                slice.ptr = @ptrCast([*]T, @alignCast(@alignOf(T), self.dense[idx]));
                slice.len = self.capacity;

                self.alloc.free(slice);
            }

            inline for (SparseComponents) |T, SparseIdx| {
                const list = self.rawSparse(T);
                const mapping = &self.sparse_mapping[SparseIdx];

                list.deinit(self.alloc);
                mapping.map.deinit(self.alloc);
            }
        }

        pub fn create(self: *Self, name: []const u8) !EntityId {
            const index = index: {
                if (self.free_head != std.math.maxInt(u32)) {
                    const index = self.free_head;
                    const meta = &self.raw(Meta)[self.free_head];
                    self.free_head = @truncate(u32, meta.name.len);

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

            const meta = &self.raw(Meta)[index];
            meta.name = name;
            meta.generation = self.generation;
            meta.bitset = std.StaticBitSet(Components.len - 1).initEmpty();

            return EntityId{ .index = index, .generation = self.generation };
        }

        pub fn delete(self: *Self, id: EntityId) bool {
            const index = self.indexOf(id) orelse return false;
            const meta = &self.raw(Meta)[index];

            inline for (SparseComponents) |T, SparseIdx| {
                const Idx = comptime typeIndex(T).?;

                const list = self.rawSparse(T);
                const mapping = &self.sparse_mapping[SparseIdx];

                if (meta.bitset.isSet(Idx)) {
                    const sparse_index = mapping.map.fetchRemove(index).?.value;
                    list.items[sparse_index] = .{ .next = mapping.free_head };
                    mapping.free_head = sparse_index;
                }
            }

            meta.generation = std.math.maxInt(u32);
            meta.name = "";
            meta.name.len = self.free_head;

            self.free_head = id.index;
            self.generation += 1;

            return true;
        }

        pub fn addComponent(self: *Self, id: EntityId, component: anytype) !bool {
            const T = @TypeOf(component);
            if (T == Meta) @compileError("Tried to add a Meta component");

            const index = self.indexOf(id) orelse return false;

            const Idx = comptime typeIndex(T) orelse
                @compileError("Type not registered: " ++ @typeName(T));

            // we defer here so that we can read the previous value before
            // returning
            defer self.raw(Meta)[index].bitset.set(Idx);

            const SparseIdx = if (comptime sparseTypeIndex(T)) |I| I else {
                const elements = self.raw(T);
                elements[index] = component;

                return true;
            };

            const meta = &self.raw(Meta)[index];
            const list = self.rawSparse(T);
            const mapping = &self.sparse_mapping[SparseIdx];

            if (meta.bitset.isSet(Idx)) {
                const sparse_index = mapping.map.get(index) orelse unreachable;
                list.items[sparse_index] = .{ .t = component };

                return true;
            }

            if (mapping.free_head != std.math.maxInt(u32)) {
                const sparse_index = mapping.free_head;
                mapping.free_head = list.items[sparse_index].next;

                try mapping.map.put(self.alloc, index, sparse_index);
                list.items[sparse_index] = .{ .t = component };
                return true;
            }

            const sparse_index: u32 = @truncate(u32, list.items.len);
            try mapping.map.put(self.alloc, index, sparse_index);
            try list.append(self.alloc, .{ .t = component });

            return true;
        }

        fn rawSparse(self: *Self, comptime T: type) *List(FreeEnt(T)) {
            if (comptime sparseTypeIndex(T)) |SparseIdx| {
                const list = @ptrCast(*List(FreeEnt(T)), &self.sparse[SparseIdx]);
                return list;
            }

            if (comptime denseTypeIndex(T)) |_| {
                @compileError("Type not sparse: " ++ @typeName(T));
            }

            @compileError("Type not registered: " ++ @typeName(T));
        }

        fn raw(self: *Self, comptime T: type) []T {
            if (comptime denseTypeIndex(T)) |Idx| {
                var slice: []T = &.{};
                slice.len = self.len;

                if (@sizeOf(T) > 0) {
                    slice.ptr = @ptrCast([*]T, @alignCast(@alignOf(T), self.dense[Idx]));
                }

                return slice;
            }

            if (comptime sparseTypeIndex(T)) |_| {
                @compileError("Type not dense: " ++ @typeName(T));
            }

            @compileError("Type not registered: " ++ @typeName(T));
        }

        pub fn view(self: *Self, comptime ViewType: type) RegistryView(Self, ViewType) {
            return .{ .registry = self };
        }

        fn indexOf(self: *Self, id: EntityId) ?u32 {
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

        fn sparseTypeIndex(comptime T: type) ?usize {
            for (SparseComponents) |Component, idx| {
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

    const RegistryType = Registry(&.{ TransformComponent, MoveComponent }, &.{});

    var registry = try RegistryType.init(256, liu.Pages);
    defer registry.deinit();

    var success = false;

    var i: u32 = 0;
    while (i < 257) : (i += 1) {
        const meh = try registry.create("meh");
        success = try registry.addComponent(meh, TransformComponent{ .i = meh.index });
        try std.testing.expect(success);
    }

    try std.testing.expect(registry.len == 257);
    try std.testing.expect(registry.capacity > 256);

    const View = struct {
        transform: ?TransformComponent,
        move: ?*MoveComponent,
    };

    var view = registry.view(View);
    while (view.next()) |elem| {
        try std.testing.expect(elem.meta.name.len == 3);
        if (elem.transform) |t|
            try std.testing.expect(t.i == elem.id.index)
        else
            try std.testing.expect(false);

        try std.testing.expect(elem.move == null);
    }
}

test "Registry: sparse" {
    const TransformComponent = struct { i: u32 };
    const Empty = struct {};
    const MoveComponent = struct { i: u32 };

    const RegistryType = Registry(&.{ TransformComponent, Empty }, &.{MoveComponent});

    var registry = try RegistryType.init(256, liu.Pages);
    defer registry.deinit();

    const View = struct {
        transform: ?*TransformComponent,
        move: ?*MoveComponent,
    };

    var i: u32 = 0;
    var success = false;

    while (i < 100) : (i += 1) {
        const meh = try registry.create("meh");
        if (i % 2 == 0) {
            success = try registry.addComponent(meh, TransformComponent{ .i = i });
            try std.testing.expect(success);
        }

        if (i % 4 == 0) {
            success = try registry.addComponent(meh, Empty{});
            try std.testing.expect(success);
        }

        if (i % 8 == 0) {
            success = try registry.addComponent(meh, MoveComponent{ .i = i });
            try std.testing.expect(success);
        }
    }

    const deh = try registry.create("dehh");

    success = try registry.addComponent(deh, MoveComponent{ .i = 1 });
    try std.testing.expect(success);

    try std.testing.expect(registry.delete(deh));

    var view = registry.view(View);
    var count: u32 = 0;
    var sparse_count: u32 = 0;
    while (view.next()) |elem| {
        try std.testing.expect(elem.meta.name.len == 3);

        if (elem.transform) |transform| {
            try std.testing.expect(transform.i == count);
        }

        if (elem.move) |move| {
            try std.testing.expect(move.i == count);
            sparse_count += 1;
        }

        const elem2 = view.get(elem.id) orelse
            return error.TestUnexpectedResult;

        try std.testing.expect(elem.id.index == elem2.id.index);
        try std.testing.expect(elem.id.generation == elem2.id.generation);
        try std.testing.expect(elem.meta == elem2.meta);
        try std.testing.expect(elem.transform == elem2.transform);
        try std.testing.expect(elem.move == elem2.move);

        count += 1;
    }

    try std.testing.expect(count == 100);
    try std.testing.expect(sparse_count == (100 / 8) + 1);

    view.reset();
}

test "Registry: delete" {
    const TransformComponent = struct {};
    const MoveComponent = struct {};

    const RegistryType = Registry(&.{ TransformComponent, MoveComponent }, &.{});

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
        try std.testing.expect(elem.meta.name.len == 3);
        count += 1;
    }

    try std.testing.expect(count == 1);

    view.reset();
}
