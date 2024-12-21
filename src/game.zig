const std = @import("std");
const ray = @cImport({
    @cInclude("raylib.h");
});
const global = @import("global.zig");
const sprite = @import("sprite.zig");
const stage = @import("stage.zig");
const player = @import("player.zig");

pub fn init() !void {
    ray.InitWindow(global.SCREEN_WIDTH, global.SCREEN_HEIGHT, global.TITLE);
    ray.InitAudioDevice();

    // initialize sprites
    global.sprites = try std.heap.page_allocator.alloc(sprite.Sprite, sprite.SpriteImages.len);
    for (sprite.SpriteImages, 0..) |image, idx| {
        try loadSprite(image, idx);
    }

    // load tile counts
    for (sprite.tileCounts) |tc| {
        loadTileCount(tc);
    }

    for (stage.Villains) |villain| {
        global.sprites[global.findSpriteImagesIndex(try std.fmt.allocPrint(std.heap.page_allocator, "{s}_normal", .{villain}))].frameSpeed = stage.VILLAIN_SPRITE_FRAME_SPEED;
        global.sprites[global.findSpriteImagesIndex(try std.fmt.allocPrint(std.heap.page_allocator, "{s}_kick", .{villain}))].frameSpeed = stage.VILLAIN_SPRITE_FRAME_SPEED;
        global.sprites[global.findSpriteImagesIndex(try std.fmt.allocPrint(std.heap.page_allocator, "{s}_other", .{villain}))].frameSpeed = stage.VILLAIN_SPRITE_FRAME_SPEED;
    }

    //initialize musics
    global.musics = try std.heap.page_allocator.alloc(ray.Music, global.MusicsList.len);
    for (global.MusicsList, 0..) |music, idx| {
        try loadMusic(music, idx);
    }

    //initialize sounds
    global.sounds = try std.heap.page_allocator.alloc(ray.Sound, global.SoundsList.len);
    for (global.SoundsList, 0..) |sound, idx| {
        try loadSound(sound, idx);
    }

    // initialize stages
    try stage.titleStage.new();
    try stage.viewStage.new();
    try stage.gameStage.new();

    //initialize player
    try player.player.new();

    ray.SetTargetFPS(global.TARGET_FPS);
}

pub fn run() !void {
    while (true) {
        if (ray.IsKeyDown(ray.KEY_ESCAPE) or ray.WindowShouldClose())
            break;

        switch (global.state) {
            .STAGE_VIEW => {
                try stage.viewStage.run(stage.viewStageInitFunction, stage.viewStageDrawFunction, stage.viewStageOnTimeTickFunction, stage.viewStageOnHandleKeysFunction, stage.viewStageOnRunFunction);
            },
            .STAGE_GAME => {
                try stage.gameStage.run(stage.gameStageInitFunction, stage.gameStageDrawFunction, stage.gameStageOnTimeTickFunction, stage.gameStageOnHandleKeysFunction, stage.gameStageOnRunFunction);
            },
            else => {
                try stage.titleStage.run(stage.titleStageInitFunction, stage.titleStageDrawFunction, stage.titleStageOnTimeTickFunction, stage.titleStageOnHandleKeysFunction, stage.titleStageOnRunFunction);
            },
        }
    }

    try cleanUp();
}

fn cleanUp() !void {
    //unload sprite textures
    for (global.sprites, 0..) |_, idx| {
        try global.sprites[idx].unload();
    }

    //unload musics
    for (global.MusicsList, 0..) |_, idx| {
        ray.UnloadMusicStream(global.musics[idx]);
    }

    //unload sounds
    for (global.SoundsList, 0..) |_, idx| {
        ray.UnloadSound(global.sounds[idx]);
    }

    // unload render textures on stages
    try stage.titleStage.unloadTexture();
    try stage.viewStage.unloadTexture();
    try stage.gameStage.unloadTexture();

    std.heap.page_allocator.free(global.sprites);
    std.heap.page_allocator.free(global.musics);
    std.heap.page_allocator.free(global.sounds);
    ray.CloseAudioDevice();
    ray.CloseWindow();
}

fn loadMusic(name: []const u8, index: u64) !void {
    const musicPath: [*c]const u8 = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}musics/{s}.mp3", .{ global.ASSETS_PATH, name });
    global.musics[index] = ray.LoadMusicStream(musicPath);
}

fn loadSound(name: []const u8, index: u64) !void {
    const soundPath: [*c]const u8 = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}sounds/{s}.wav", .{ global.ASSETS_PATH, name });
    global.sounds[index] = ray.LoadSound(soundPath);
}

fn loadSprite(name: []const u8, index: u64) !void {
    const imagePath: [*c]const u8 = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}images/{s}.png", .{ global.ASSETS_PATH, name });
    const txt = ray.LoadTexture(imagePath);

    const rect = ray.Rectangle{
        .x = 0,
        .y = 0,
        .width = @as(f32, @floatFromInt(txt.width)),
        .height = @as(f32, @floatFromInt(txt.height)),
    };

    var spr = sprite.Sprite{
        .texture = txt,
        .x = 0,
        .y = 0,
        .frameRect = rect,
        .frameSpeed = global.FRAME_SPEED,
        .tileCount = 0,
        .currentFrame = 0,
        .framesCounter = 0,
    };
    spr.x = 0;

    global.sprites[index] = spr;
}

fn loadTileCount(tileCount: sprite.TileCount) void {
    global.sprites[global.findSpriteImagesIndex(tileCount.name)].setTileCount(tileCount.count);
}
