const ray = @cImport({
    @cInclude("raylib.h");
});
const global = @import("global.zig");

pub const LETTER_WIDTH = 8;

pub const SpriteImages = [_][]const u8{ "title", "konami_logo", "letters", "game_bg", "player_normal", "player_down", "player_stand_punch", "player_sit_punch", "player_stand_kick", "player_sit_kick", "player_high_kick", "player_flying_kick", "life", "health_hud", "health_green", "health_red", "wang_normal", "tao_normal", "chen_normal", "lang_normal", "spinning_chain", "hit", "wang_dead", "tao_dead", "chen_dead", "lang_dead", "player_smile", "mu_normal", "mu_dead", "wang_kick", "tao_kick", "chen_kick", "lang_kick", "mu_kick", "wang_other", "tao_other", "chen_other", "lang_other", "mu_other", "wang_hit", "tao_hit", "chen_hit", "lang_hit", "mu_hit", "player_dead" };

pub const CopyrightText: []const u8 = "* 1985 konami";
pub const OtherText: []const u8 = "* 2024 silva";
pub const ToStartText: []const u8 = "press enter to start";

pub const SpriteLetters = [_][]const u8{
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "y",
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "-",
    " ",
    "*",
};

pub const Sprite = struct {
    x: i16,
    y: i16,
    texture: ray.Texture2D,
    tileCount: u8,
    currentFrame: u8,
    framesCounter: u8,
    frameRect: ray.Rectangle,
    frameSpeed: u8,
    paused: bool = false,

    pub fn unload(self: *Sprite) !void {
        ray.UnloadTexture(self.texture);
    }

    pub fn draw(self: *Sprite) !void {
        const v2 = ray.Vector2{
            .x = @as(f32, @floatFromInt(self.x)),
            .y = @as(f32, @floatFromInt(self.y)),
        };
        ray.DrawTextureRec(self.texture, self.frameRect, v2, ray.WHITE);
    }

    pub fn drawByIndex(self: *Sprite, index: u64) !void {
        self.frameRect.x = @as(f32, @floatFromInt(index)) * @as(f32, @floatFromInt(self.texture.width)) / @as(f32, @floatFromInt(self.tileCount));
        try self.draw();
    }

    pub fn setTileCount(self: *Sprite, count: u8) !void {
        self.tileCount = count;
        const rect = ray.Rectangle{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(self.texture.width)) / @as(f32, @floatFromInt(self.tileCount)),
            .height = @as(f32, @floatFromInt(self.texture.height)),
        };
        self.frameRect = rect;
    }

    pub fn flipHorizontal(self: *Sprite) !void {
        self.frameRect.width = -self.frameRect.width;
    }

    pub fn play(self: *Sprite) bool {
        var isLastFrame = false;
        self.framesCounter += 1;

        if (self.framesCounter >= (global.TARGET_FPS / self.frameSpeed)) {
            self.framesCounter = 0;

            if (!self.paused) self.currentFrame += 1;

            if (self.currentFrame > (self.tileCount - 1)) {
                self.currentFrame = 0;
                isLastFrame = true;
            }
            self.frameRect.x = @as(f32, @floatFromInt(self.currentFrame)) * @as(f32, @floatFromInt(self.texture.width)) / @as(f32, @floatFromInt(self.tileCount));
        }

        try self.draw();
        return isLastFrame;
    }
    pub fn resetCurrentFrame(self: *Sprite) void {
        self.currentFrame = 0;
        self.framesCounter = 0;
    }
};
