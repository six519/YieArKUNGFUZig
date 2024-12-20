const ray = @cImport({
    @cInclude("raylib.h");
});
const std = @import("std");
const sprite = @import("sprite.zig");

pub const SCREEN_WIDTH = 1024;
pub const SCREEN_HEIGHT = 768;
pub const TITLE = "Yie Ar KUNG~FU";
pub const TARGET_FPS = 60;
pub const FRAME_SPEED = 5;
pub const ASSETS_PATH = "assets/";
pub const GAME_WIDTH = 256;
pub const GAME_HEIGHT = 240;
pub const DEFAULT_HEALTH = 9;
pub const STAGE_BOUNDARY = 15;
pub const VERSION = "0-0-1";
pub const LOW_HEALTH = 4;

pub const GameState = enum { STAGE_START, STAGE_VIEW, STAGE_GAME };

pub var state: GameState = GameState.STAGE_START;
pub var stage: u8 = 1;
pub var score: u32 = 0;

pub var sprites: []sprite.Sprite = undefined;
pub var musics: []ray.Music = undefined;
pub var sounds: []ray.Sound = undefined;

pub const voidFunc = fn () void;

pub const MusicsList = [_][]const u8{
    "bg",
};

pub const SoundsList = [_][]const u8{
    "attack",
    "collided",
    "dead",
    "win",
    "counting",
    "game_over",
    "collided2",
    "feet_sound",
    "low_health",
};

pub const CollisionInfo = struct {
    x1: i16,
    x2: i16,
    y: i16,
    width: u16,
    height: u16,
    minusXKick: i16,
};

pub fn findSpriteImagesIndex(text: []const u8) u64 {
    for (sprite.SpriteImages, 0..) |arr, idx| {
        if (std.mem.eql(u8, arr, text)) return idx;
    }
    return sprite.SpriteImages.len + 1; // this will cause error
}

pub fn getRandomNumber(min: u8, max: u8) !u8 {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    return rand.intRangeAtMost(u8, min, max);
}
