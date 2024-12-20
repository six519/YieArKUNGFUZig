const std = @import("std");
const ray = @cImport({
    @cInclude("raylib.h");
});
const global = @import("global.zig");
const sprite = @import("sprite.zig");
const player = @import("player.zig");

pub const VILLAIN_SPRITE_FRAME_SPEED = 3;
pub const SPINNING_CHAIN_SPEED = 6;
pub const VILLAIN_DEFAULT_X = 147;
pub const VILLAIN_DEFAULT_Y = 152;
pub const VILLAIN_MOVE_NONE = -1;
pub const VILLAIN_MOVE_IDLE = 0;
pub const VILLAIN_MOVE_LEFT = 1;
pub const VILLAIN_MOVE_RIGHT = 2;
pub const VILLAIN_MOVE_DEAD = 3;
pub const VILLAIN_MOVE_KICK = 4;
pub const VILLAIN_MOVE_OTHER = 5;
pub const VILLAIN_MOVE_SPECIAL = 6;
pub const VILLAIN_MOVE_PAUSE = 7;
pub const VILLAIN_FRAME_SPEED = 21;
pub const VILLAIN_FB_SPEED = 1;
pub const VILLAIN_SPRITE_FRAME_SPEED_RUN = 7;
pub const VILLAIN_FB_SPEED_RUN = 5;
pub const VILLAIN_RUN_BOUNDARY = 30;
pub const VILLAIN_BACK_DISTANCE = 10;

pub const MOVE_STATE_FOLLOW_PLAYER = 0;
pub const MOVE_STATE_FORWARD_WITH_ATTACK = 1;
pub const MOVE_STATE_RUNNING_LEFT = 2;
pub const MOVE_STATE_RUNNING_RIGHT = 3;

pub const END_STATE_START = 0;
pub const END_STATE_PLAY_SOUND = 1;
pub const END_STATE_SHOWTIME = 2;
pub const END_STATE_SHOWTIME_HK1 = 3;
pub const END_STATE_SHOWTIME_LK1 = 4;
pub const END_STATE_SHOWTIME_LK2 = 5;
pub const END_STATE_SHOWTIME_HK2 = 6;
pub const END_STATE_SHOWTIME_P = 7;
pub const END_STATE_SMILE = 8;
pub const END_STATE_COUNT_LIFE = 9;
pub const END_STATE_END = 10;
pub const END_STATE_GAME_OVER = 11;

pub const END_STATE_VILLAIN_START = 0;
pub const END_STATE_VILLAIN_LIE_DOWN = 1;
pub const END_STATE_VILLAIN_MOVE_FEET = 2;
pub const END_STATE_VILLAIN_END = 3;
pub const END_STATE_VILLAIN_GAME_OVER = 4;

pub const HIGH_TIME = 2;
pub const LOW_TIME = 1;

pub const Villains = [_][]const u8{
    "wang",
    "tao",
    "chen",
    "lang",
    "mu",
};

pub const VillainSprites = [_][]const u8{
    "kick",
    "other",
    "normal",
    "dead",
    "hit",
};

pub const collisionsInfo: [5]global.CollisionInfo = [_]global.CollisionInfo{
    global.CollisionInfo{ .x1 = 5, .x2 = 6, .y = 8, .width = 16, .height = 32, .minusXKick = 11 },
    global.CollisionInfo{ .x1 = 7, .x2 = 4, .y = 8, .width = 5, .height = 32, .minusXKick = 12 },
    global.CollisionInfo{ .x1 = 9, .x2 = 7, .y = 8, .width = 16, .height = 32, .minusXKick = 8 },
    global.CollisionInfo{ .x1 = 7, .x2 = 4, .y = 9, .width = 9, .height = 31, .minusXKick = 7 },
    global.CollisionInfo{ .x1 = 12, .x2 = 2, .y = 8, .width = 17, .height = 32, .minusXKick = 6 },
};

const collisionsKickInfo: [5]global.CollisionInfo = [_]global.CollisionInfo{
    global.CollisionInfo{ .x1 = 0, .x2 = 44, .y = 20, .width = 6, .height = 4, .minusXKick = 0 },
    global.CollisionInfo{ .x1 = 0, .x2 = 33, .y = 20, .width = 6, .height = 4, .minusXKick = 0 },
    global.CollisionInfo{ .x1 = 0, .x2 = 35, .y = 13, .width = 5, .height = 2, .minusXKick = 0 },
    global.CollisionInfo{ .x1 = 0, .x2 = 25, .y = 8, .width = 4, .height = 6, .minusXKick = 0 },
    global.CollisionInfo{ .x1 = 0, .x2 = 33, .y = 26, .width = 6, .height = 4, .minusXKick = 0 },
};

const collisionsOtherInfo: [5]global.CollisionInfo = [_]global.CollisionInfo{
    global.CollisionInfo{ .x1 = 0, .x2 = 47, .y = 26, .width = 3, .height = 2, .minusXKick = 0 },
    global.CollisionInfo{ .x1 = 7, .x2 = 29, .y = 15, .width = 3, .height = 2, .minusXKick = 0 },
    global.CollisionInfo{ .x1 = 0, .x2 = 37, .y = 19, .width = 3, .height = 3, .minusXKick = 0 },
    global.CollisionInfo{ .x1 = 0, .x2 = 23, .y = 36, .width = 6, .height = 3, .minusXKick = 0 },
    global.CollisionInfo{ .x1 = 7, .x2 = 29, .y = 15, .width = 3, .height = 3, .minusXKick = 0 },
};

const attackList = [_]i16{
    VILLAIN_MOVE_KICK,
    VILLAIN_MOVE_OTHER,
};

const TextInfo = struct {
    currentFrame: u16 = 0,
    framesCounter: u16 = 0,
};

var textInfos: [14]TextInfo = [_]TextInfo{
    TextInfo{},
    TextInfo{},
    TextInfo{},
    TextInfo{},
    TextInfo{},
    TextInfo{},
    TextInfo{},
    TextInfo{},
    TextInfo{},
    TextInfo{},
    TextInfo{},
    TextInfo{},
    TextInfo{},
    TextInfo{},
};

const Stage = struct {
    timeCounter: u16 = 0,
    timeSeconds: u16 = 0,
    renderTexture: ray.RenderTexture2D,
    initialized: bool,
    blinkEnter: bool = false,
    maxBlink: u16 = 4,
    blinkCount: u16 = 0,
    canEnter: bool = true,
    showVillainHit: bool,
    villainEndState: u8 = END_STATE_VILLAIN_START,
    endState: u8 = END_STATE_START,
    villainX: i16,
    villainY: i16,
    villainHealth: u8 = global.DEFAULT_HEALTH,
    pauseMovement: bool = false,
    villainCurrentMove: i16 = VILLAIN_MOVE_NONE,
    villainMovementCounter: u16,
    isVillainFlipped: bool = false,
    spinningChainX: i16,
    spinningChainY: i16,
    haltTime: u16,
    haltTimeHit: u16,
    maxHaltTime: u16,
    villainMoveState: u8 = MOVE_STATE_FOLLOW_PLAYER,
    villainRandomAttack: u8 = 0,
    runCounter: u8 = 0,

    pub fn new(self: *Stage) !void {
        try self.cleanUp();
        self.renderTexture = ray.LoadRenderTexture(global.GAME_WIDTH, global.GAME_HEIGHT);
    }

    pub fn cleanUp(self: *Stage) !void {
        self.initialized = false;
        self.timeSeconds = 0;
        self.timeCounter = 0;
    }

    pub fn draw(self: *Stage, stageDrawFunction: global.voidFunc) !void {
        ray.BeginDrawing();
        ray.BeginTextureMode(self.renderTexture);

        ray.ClearBackground(ray.BLACK);
        stageDrawFunction();
        ray.EndTextureMode();

        const srcRect = ray.Rectangle{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(global.GAME_WIDTH)),
            .height = @as(f32, @floatFromInt(-global.GAME_HEIGHT)),
        };

        const dstRect = ray.Rectangle{
            .x = (@as(f32, @floatFromInt(global.SCREEN_WIDTH)) / 2.0) - ((@as(f32, @floatFromInt(global.SCREEN_WIDTH)) * (@as(f32, @floatFromInt(global.GAME_HEIGHT)) / @as(f32, @floatFromInt(global.GAME_WIDTH)))) / 2.0),
            .y = 0,
            .width = @as(f32, @floatFromInt(global.SCREEN_WIDTH)) * (@as(f32, @floatFromInt(global.GAME_HEIGHT)) / @as(f32, @floatFromInt(global.GAME_WIDTH))),
            .height = @as(f32, @floatFromInt(global.SCREEN_HEIGHT)),
        };

        const v2 = ray.Vector2{
            .x = 0,
            .y = 0,
        };
        ray.DrawTexturePro(self.renderTexture.texture, srcRect, dstRect, v2, 0.0, ray.WHITE);

        ray.EndDrawing();
    }

    pub fn run(self: *Stage, initFunction: global.voidFunc, stageDrawFunction: global.voidFunc, onTimeTickFunction: global.voidFunc, onHandleKeysFunction: global.voidFunc, onRunFunction: global.voidFunc) !void {
        if (!self.initialized) {
            initFunction();
            self.initialized = true;
        }
        try self.draw(stageDrawFunction);
        try self.timeTick(onTimeTickFunction);
        onHandleKeysFunction();
        onRunFunction();
    }

    pub fn timeTick(self: *Stage, onTimeTickFunction: global.voidFunc) !void {
        self.timeCounter += 1;

        if (self.timeCounter >= (global.TARGET_FPS / global.FRAME_SPEED)) {
            self.timeCounter = 0;

            if (self.timeSeconds == 59) {
                self.timeSeconds = 0;
                onTimeTickFunction();
                return;
            }

            self.timeSeconds += 1;
            onTimeTickFunction();
        }
    }

    pub fn unloadTexture(self: *Stage) !void {
        ray.UnloadRenderTexture(self.renderTexture);
    }

    pub fn drawText(_: *Stage, index: u16, text: []const u8, x: i16, y: i16, blink: bool, onBlinkingDoneFunction: global.voidFunc) void {
        global.sprites[global.findSpriteImagesIndex("letters")].x = x;
        global.sprites[global.findSpriteImagesIndex("letters")].y = y;

        if (blink) {
            textInfos[index].framesCounter += 1;

            if (textInfos[index].framesCounter >= (global.TARGET_FPS / global.FRAME_SPEED)) {
                textInfos[index].framesCounter = 0;

                textInfos[index].currentFrame += 1;

                if (textInfos[index].currentFrame > 1) {
                    textInfos[index].currentFrame = 0;
                    onBlinkingDoneFunction();
                }
            }
        }

        for (text) |c| {
            var letterIndex: u64 = 0;
            var notFound = true;
            for (sprite.SpriteLetters, 0..) |l, idx| {
                if (c == l[0]) {
                    letterIndex = idx;
                    notFound = false;
                    break;
                }
            }

            if (notFound) {
                return;
            }

            if (!blink) {
                try global.sprites[global.findSpriteImagesIndex("letters")].drawByIndex(letterIndex);
                global.sprites[global.findSpriteImagesIndex("letters")].x += sprite.LETTER_WIDTH;
                continue;
            }

            //blinking
            if (textInfos[index].currentFrame == 1) {
                try global.sprites[global.findSpriteImagesIndex("letters")].drawByIndex(letterIndex);
                global.sprites[global.findSpriteImagesIndex("letters")].x += sprite.LETTER_WIDTH;
                continue;
            }

            try global.sprites[global.findSpriteImagesIndex("letters")].drawByIndex(sprite.SpriteLetters.len - 2);
            global.sprites[global.findSpriteImagesIndex("letters")].x += sprite.LETTER_WIDTH;
        }
    }
};

pub var titleStage = Stage{
    .renderTexture = undefined,
    .initialized = false,
    .showVillainHit = false,
    .villainX = VILLAIN_DEFAULT_X,
    .villainY = VILLAIN_DEFAULT_Y,
    .villainMovementCounter = 0,
    .spinningChainX = 140,
    .spinningChainY = 155,
    .haltTime = 0,
    .haltTimeHit = 0,
    .maxHaltTime = HIGH_TIME,
};

pub fn titleStageInitFunction() void {
    global.sprites[global.findSpriteImagesIndex("konami_logo")].y = 35;
    var w = @as(i16, @intCast(global.sprites[global.findSpriteImagesIndex("konami_logo")].texture.width));
    global.sprites[global.findSpriteImagesIndex("konami_logo")].x = (global.GAME_WIDTH / 2) - (@divTrunc(w, 2));

    w = @as(i16, @intCast(global.sprites[global.findSpriteImagesIndex("title")].texture.width));
    global.sprites[global.findSpriteImagesIndex("title")].y = 85;
    global.sprites[global.findSpriteImagesIndex("title")].x = (global.GAME_WIDTH / 2) - (@divTrunc(w, 2));
}

pub fn titleStageDrawFunction() void {
    try global.sprites[global.findSpriteImagesIndex("konami_logo")].draw();
    try global.sprites[global.findSpriteImagesIndex("title")].draw();

    titleStage.drawText(0, sprite.CopyrightText, (global.GAME_WIDTH / 2) - ((sprite.CopyrightText.len * sprite.LETTER_WIDTH) / 2), 110, false, titleStageOnBlinkingDoneFunction);
    titleStage.drawText(1, sprite.OtherText, (global.GAME_WIDTH / 2) - ((sprite.OtherText.len * sprite.LETTER_WIDTH) / 2), 120, false, titleStageOnBlinkingDoneFunction);

    titleStage.drawText(2, sprite.ToStartText, (global.GAME_WIDTH / 2) - ((sprite.ToStartText.len * sprite.LETTER_WIDTH) / 2), 165, titleStage.blinkEnter, titleStageOnBlinkingDoneFunction);
}

pub fn titleStageOnTimeTickFunction() void {
    // blank for now
}

pub fn titleStageOnHandleKeysFunction() void {
    if ((ray.IsKeyDown(ray.KEY_ENTER) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_MIDDLE_RIGHT))) and !titleStage.blinkEnter and titleStage.canEnter) {
        titleStage.blinkEnter = true;
        ray.PlayMusicStream(global.musics[0]); //bg
    } else if ((ray.IsKeyReleased(ray.KEY_ENTER) or (ray.IsGamepadButtonReleased(0, ray.GAMEPAD_BUTTON_MIDDLE_RIGHT) and ray.IsGamepadAvailable(0)))) {
        titleStage.canEnter = true;
    }
}

pub fn titleStageCleanUpFunction() void {
    titleStage.blinkEnter = false;
    titleStage.blinkCount = 0;
    try titleStage.cleanUp();
}

pub fn titleStageOnBlinkingDoneFunction() void {
    if (titleStage.blinkCount == titleStage.maxBlink) {
        global.state = global.GameState.STAGE_VIEW;
        titleStageCleanUpFunction();
        return;
    }
    titleStage.blinkCount += 1;
}

pub fn titleStageOnRunFunction() void {
    // blank for now
}

pub var viewStage = Stage{
    .renderTexture = undefined,
    .initialized = false,
    .showVillainHit = false,
    .villainX = VILLAIN_DEFAULT_X,
    .villainY = VILLAIN_DEFAULT_Y,
    .villainMovementCounter = 0,
    .spinningChainX = 140,
    .spinningChainY = 155,
    .haltTime = 0,
    .haltTimeHit = 0,
    .maxHaltTime = HIGH_TIME,
};

pub fn viewStageInitFunction() void {
    // blank for now
}

pub fn viewStageDrawFunction() void {
    const str = "stage 0";
    var conStr: [100]u8 = undefined;
    var start: usize = 0;
    _ = &start;
    const conStrSlice = conStr[start..];
    const res = std.fmt.bufPrint(conStrSlice, "{s}{d}", .{ str, global.stage }) catch |err| {
        std.debug.print("Error on res: {}\n", .{err});
        return;
    };

    gameStage.drawText(3, res, (global.GAME_WIDTH / 2) - ((8 * sprite.LETTER_WIDTH) / 2), (global.GAME_HEIGHT / 2) - (sprite.LETTER_WIDTH / 2), false, gameStageOnBlinkingDoneFunction);

    ray.UpdateMusicStream(global.musics[0]); //bg

}

pub fn viewStageOnTimeTickFunction() void {
    if (viewStage.timeSeconds == 10) {
        global.state = global.GameState.STAGE_GAME;
        viewStageCleanUpFunction();
    }
}

pub fn viewStageOnHandleKeysFunction() void {
    // blank for now
}

pub fn viewStageCleanUpFunction() void {
    try viewStage.cleanUp();
}

pub fn viewStageOnBlinkingDoneFunction() void {
    // blank for now
}

pub fn viewStageOnRunFunction() void {
    // blank for now
}

pub var gameStage = Stage{
    .renderTexture = undefined,
    .initialized = false,
    .showVillainHit = false,
    .villainX = VILLAIN_DEFAULT_X,
    .villainY = VILLAIN_DEFAULT_Y,
    .villainMovementCounter = 0,
    .spinningChainX = 140,
    .spinningChainY = 155,
    .haltTime = 0,
    .haltTimeHit = 0,
    .maxHaltTime = HIGH_TIME,
};

pub fn gameStageGoDirection(condition: bool, isRight: bool) void {
    if (gameStage.runCounter > VILLAIN_BACK_DISTANCE) {
        gameStage.villainMoveState = MOVE_STATE_FOLLOW_PLAYER;
        const str_spr = std.fmt.allocPrint(std.heap.page_allocator, "{s}_normal", .{Villains[global.stage - 1]}) catch |err| {
            std.debug.print("Error on str_spr: {}\n", .{err});
            return;
        };

        global.sprites[global.findSpriteImagesIndex(str_spr)].frameSpeed = VILLAIN_SPRITE_FRAME_SPEED;
        return;
    }
    if (condition) {
        gameStageVillainModifyX(VILLAIN_FB_SPEED_RUN, isRight);
        gameStage.runCounter += 1;
        return;
    }
    gameStage.villainMoveState = if (isRight) MOVE_STATE_RUNNING_LEFT else MOVE_STATE_RUNNING_RIGHT;
}

pub fn gameStageVillainRunLeft() void {
    gameStageGoDirection(gameStage.villainX > (global.STAGE_BOUNDARY + VILLAIN_RUN_BOUNDARY), false);
}

pub fn gameStageVillainRunRight() void {
    const w = @as(i16, @intCast(global.sprites[global.findSpriteImagesIndex("player_normal")].texture.width));
    gameStageGoDirection(gameStage.villainX < (global.GAME_WIDTH - (global.STAGE_BOUNDARY + VILLAIN_RUN_BOUNDARY) - @divTrunc(w, 2)), true);
}

pub fn gameStageVillainFollowPlayer() void {
    if (gameStage.villainX > player.player.x)
        gameStageVillainModifyX(VILLAIN_FB_SPEED, false);
    if (gameStage.villainX < player.player.x)
        gameStageVillainModifyX(VILLAIN_FB_SPEED, true);
}

pub fn gameStageHandleVillainMovement() void {
    switch (gameStage.villainMoveState) {
        MOVE_STATE_FORWARD_WITH_ATTACK => {
            //nothing to do?
        },
        MOVE_STATE_RUNNING_LEFT => {
            gameStage.villainCurrentMove = VILLAIN_MOVE_IDLE;
            gameStageVillainRunLeft();
        },
        MOVE_STATE_RUNNING_RIGHT => {
            gameStage.villainCurrentMove = VILLAIN_MOVE_IDLE;
            gameStageVillainRunRight();
        },
        else => {
            // MOVE_STATE_FOLLOW_PLAYER
            gameStageVillainFollowPlayer();

            if (gameStageIsVillainNearPlayer()) {
                gameStageVillainSimpleAttack();
            }
        },
    }
}

pub fn gameStageVillainSimpleAttack() void {
    gameStage.villainMoveState = MOVE_STATE_FORWARD_WITH_ATTACK;
    gameStage.villainRandomAttack = global.getRandomNumber(0, 1) catch |err| {
        std.debug.print("Error on villainRandomAttack: {}\n", .{err});
        return;
    };
    gameStage.villainCurrentMove = attackList[gameStage.villainRandomAttack];
}

pub fn gameStageIsVillainNearPlayer() bool {
    const w = @as(i16, @intCast(global.sprites[global.findSpriteImagesIndex("player_normal")].texture.width));
    const boundary = @divTrunc(w, global.sprites[global.findSpriteImagesIndex("player_normal")].tileCount) + 10;

    return (gameStage.villainX >= player.player.x - boundary and gameStage.isVillainFlipped) or
        (gameStage.villainX <= player.player.x + boundary and !gameStage.isVillainFlipped);
}

pub fn gameStageVillainMovementTick() void {
    gameStage.villainMovementCounter += 1;
    if (gameStage.villainMovementCounter >= (global.TARGET_FPS / VILLAIN_FRAME_SPEED)) {
        gameStage.villainMovementCounter = 0;
        gameStageHandleVillainMovement();
    }
}

pub fn gameStageReset() void {
    gameStage.villainCurrentMove = VILLAIN_MOVE_IDLE;
    gameStage.villainHealth = global.DEFAULT_HEALTH;
    gameStage.pauseMovement = false;
    gameStage.villainMovementCounter = 0;
    gameStage.villainX = VILLAIN_DEFAULT_X;
    gameStage.villainY = VILLAIN_DEFAULT_Y;
    gameStage.showVillainHit = false;
    gameStage.villainEndState = END_STATE_VILLAIN_START;
    gameStage.endState = END_STATE_START;
    gameStage.spinningChainX = 140;
    gameStage.spinningChainY = 155;
    gameStage.haltTime = 0;
    gameStage.haltTimeHit = 0;
    gameStage.maxHaltTime = HIGH_TIME;
    gameStage.villainMoveState = MOVE_STATE_FOLLOW_PLAYER;

    if (gameStage.isVillainFlipped) {
        gameStageFlipVillainSprites();
    }
}

pub fn gameStageInitFunction() void {
    global.sprites[global.findSpriteImagesIndex("life")].y = 48;
    global.sprites[global.findSpriteImagesIndex("health_hud")].y = 208;
    const w = @as(i16, @intCast(global.sprites[global.findSpriteImagesIndex("health_hud")].texture.width));
    global.sprites[global.findSpriteImagesIndex("health_hud")].x = (global.GAME_WIDTH / 2) - (@divTrunc(w, 2));

    global.sprites[global.findSpriteImagesIndex("health_green")].y = 210;
    global.sprites[global.findSpriteImagesIndex("health_red")].y = 210;
    global.sprites[global.findSpriteImagesIndex("health_red")].frameSpeed = SPINNING_CHAIN_SPEED;
    gameStageReset();
}

pub fn gameStageDrawFunction() void {
    ray.UpdateMusicStream(global.musics[0]); //bg

    // background is the last to draw
    try global.sprites[global.findSpriteImagesIndex("game_bg")].draw();

    gameStage.drawText(4, sprite.OtherText, (global.GAME_WIDTH / 2) - ((sprite.OtherText.len * sprite.LETTER_WIDTH) / 2), 24, false, gameStageOnBlinkingDoneFunction);

    const str = "stage-0";
    var conStr: [100]u8 = undefined;
    var start: usize = 0;
    _ = &start;
    const conStrSlice = conStr[start..];
    var res = std.fmt.bufPrint(conStrSlice, "{s}{d}", .{ str, global.stage }) catch |err| {
        std.debug.print("Error on res: {}\n", .{err});
        return;
    };

    gameStage.drawText(5, res, 168, 40, false, gameStageOnBlinkingDoneFunction);

    gameStage.drawText(6, "score", 24, 40, false, gameStageOnBlinkingDoneFunction);
    res = std.fmt.bufPrint(conStrSlice, "{d}", .{global.score}) catch |err| {
        std.debug.print("Error on res: {}\n", .{err});
        return;
    };
    gameStage.drawText(7, res, 24, 48, false, gameStageOnBlinkingDoneFunction);

    gameStage.drawText(8, "version", (global.GAME_WIDTH / 2) - ((7 * sprite.LETTER_WIDTH) / 2), 40, false, gameStageOnBlinkingDoneFunction);
    gameStage.drawText(9, global.VERSION, (global.GAME_WIDTH / 2) - ((5 * sprite.LETTER_WIDTH) / 2), 48, false, gameStageOnBlinkingDoneFunction);

    global.sprites[global.findSpriteImagesIndex("life")].x = 168;
    for (0..player.player.lives) |_| {
        try global.sprites[global.findSpriteImagesIndex("life")].draw();
        global.sprites[global.findSpriteImagesIndex("life")].x += 8;
    }

    gameStage.drawText(10, "ferdie", 48, (global.GAME_HEIGHT - 24), false, gameStageOnBlinkingDoneFunction);
    const converted: i16 = @intCast((Villains[global.stage - 1].len * 8));
    gameStage.drawText(11, Villains[global.stage - 1], (208 - converted), (global.GAME_HEIGHT - 24), false, gameStageOnBlinkingDoneFunction);

    try global.sprites[global.findSpriteImagesIndex("health_hud")].draw();

    global.sprites[global.findSpriteImagesIndex("health_green")].x = 104;
    global.sprites[global.findSpriteImagesIndex("health_red")].x = 104;

    //draw player's health gauge
    for (0..player.player.health) |_| {
        const h_hud = if (player.player.health > global.LOW_HEALTH) "green" else "red";
        const str_h_hud = std.fmt.allocPrint(std.heap.page_allocator, "health_{s}", .{h_hud}) catch |err| {
            std.debug.print("Error on str: {}\n", .{err});
            return;
        };
        try global.sprites[global.findSpriteImagesIndex(str_h_hud)].draw();
        global.sprites[global.findSpriteImagesIndex(str_h_hud)].x -= 8;
    }

    global.sprites[global.findSpriteImagesIndex("health_green")].x = 144;
    global.sprites[global.findSpriteImagesIndex("health_red")].x = 144;

    //draw villain's health gauge
    for (0..gameStage.villainHealth) |_| {
        const h_hud = if (gameStage.villainHealth > global.LOW_HEALTH) "green" else "red";
        const str_h_hud = std.fmt.allocPrint(std.heap.page_allocator, "health_{s}", .{h_hud}) catch |err| {
            std.debug.print("Error on str: {}\n", .{err});
            return;
        };
        try global.sprites[global.findSpriteImagesIndex(str_h_hud)].draw();
        global.sprites[global.findSpriteImagesIndex(str_h_hud)].x += 8;
    }

    // show villain
    gameStageShowVillain();

    //show player
    try player.player.play();

    if (gameStage.showVillainHit) {
        const str_hit = std.fmt.allocPrint(std.heap.page_allocator, "{s}_hit", .{Villains[global.stage - 1]}) catch |err| {
            std.debug.print("Error on str_hit: {}\n", .{err});
            return;
        };
        try global.sprites[global.findSpriteImagesIndex(str_hit)].draw();
    }

    var endText = "        ";
    var addWidth: u8 = 0;

    if (gameStage.endState == END_STATE_GAME_OVER) {
        endText = "you win ";
        addWidth = 7;
    } else {
        endText = "you lose";
        addWidth = 8;
    }

    if (gameStage.endState == END_STATE_GAME_OVER or gameStage.villainEndState == END_STATE_VILLAIN_GAME_OVER) {
        gameStage.drawText(
            12,
            "game over",
            (global.GAME_WIDTH / 2) - ((9 * sprite.LETTER_WIDTH) / 2),
            (global.GAME_HEIGHT / 2) - (sprite.LETTER_WIDTH / 2),
            false,
            gameStageOnBlinkingDoneFunction,
        );

        gameStage.drawText(
            13,
            endText,
            (global.GAME_WIDTH / 2) - (((addWidth) * sprite.LETTER_WIDTH) / 2),
            ((global.GAME_HEIGHT / 2) - (sprite.LETTER_WIDTH / 2)) + 8,
            false,
            gameStageOnBlinkingDoneFunction,
        );
    }
}

pub fn gameStageSetEndStateWithPlayerMovement(pMove: i16, flip: bool, playSound: bool) void {
    if (flip)
        try player.player.flipSprites();
    try player.player.setMovement(pMove);
    if (playSound)
        ray.PlaySound(global.sounds[0]); //attack
    gameStage.endState += 1;
}

pub fn gameStageHandleEndState() void {
    switch (gameStage.endState) {
        END_STATE_PLAY_SOUND => {
            ray.PlaySound(global.sounds[3]); //win
            gameStage.endState = END_STATE_SHOWTIME;
        },
        END_STATE_SHOWTIME => {
            gameStageSetEndStateWithPlayerMovement(player.PLAYER_STAND_PUNCH, false, true);
        },
        END_STATE_SHOWTIME_HK1 => {
            gameStageSetEndStateWithPlayerMovement(player.PLAYER_HIGH_KICK, true, true);
        },
        END_STATE_SHOWTIME_LK1 => {
            gameStageSetEndStateWithPlayerMovement(player.PLAYER_SIT_KICK, true, true);
        },
        END_STATE_SHOWTIME_LK2 => {
            gameStageSetEndStateWithPlayerMovement(player.PLAYER_SIT_KICK, true, true);
        },
        END_STATE_SHOWTIME_HK2 => {
            gameStageSetEndStateWithPlayerMovement(player.PLAYER_HIGH_KICK, true, true);
        },
        END_STATE_SHOWTIME_P => {
            gameStageSetEndStateWithPlayerMovement(player.PLAYER_STAND_PUNCH, true, true);
        },
        END_STATE_SMILE => {
            gameStageSetEndStateWithPlayerMovement(player.PLAYER_SMILE, true, false);
        },
        END_STATE_COUNT_LIFE => {
            gameStage.maxHaltTime = LOW_TIME;
            if (player.player.health > 0) {
                player.player.health -= 1;
                ray.PlaySound(global.sounds[4]); //counting
                global.score += 100;
                return;
            }
            gameStage.endState = END_STATE_END;
        },
        END_STATE_END => {
            gameStage.maxHaltTime = HIGH_TIME;
            if (global.stage == 5) {
                ray.PlaySound(global.sounds[5]); //game_over
                gameStage.endState = END_STATE_GAME_OVER;
                return;
            }
            gameStageCleanUpFunction();
            global.stage += 1;
            global.state = global.GameState.STAGE_VIEW;
            ray.PlayMusicStream(global.musics[0]);
        },
        END_STATE_GAME_OVER => {},
        else => {
            // END_STATE_START
            gameStage.villainCurrentMove = VILLAIN_MOVE_DEAD;
            ray.PlaySound(global.sounds[2]); //dead
            gameStage.endState = END_STATE_PLAY_SOUND;
        },
    }
}

pub fn gameStageHandleVillainEndState() void {
    switch (gameStage.villainEndState) {
        END_STATE_VILLAIN_LIE_DOWN => {
            try player.player.setMovement(player.PLAYER_DEAD);
            player.player.y = player.PLAYER_DEFAULT_Y;
            global.sprites[global.findSpriteImagesIndex("player_dead")].resetCurrentFrame();
            ray.PlaySound(global.sounds[2]); //dead
            gameStage.villainEndState = END_STATE_VILLAIN_MOVE_FEET;
        },
        END_STATE_VILLAIN_MOVE_FEET => {},
        END_STATE_VILLAIN_GAME_OVER => {},
        END_STATE_VILLAIN_END => {
            if (player.player.lives > 0) {
                player.player.lives -= 1;
                global.state = global.GameState.STAGE_VIEW;
                ray.PlayMusicStream(global.musics[0]);
                gameStageCleanUpFunction();
                return;
            }
            ray.PlaySound(global.sounds[5]); //game_over
            gameStage.villainEndState = END_STATE_VILLAIN_GAME_OVER;
        },
        else => {
            // END_STATE_VILLAIN_START
            gameStage.villainEndState = END_STATE_VILLAIN_LIE_DOWN;
            gameStage.villainCurrentMove = VILLAIN_MOVE_PAUSE;
            ray.StopMusicStream(global.musics[0]);
            player.player.kuyakoy = 0;
        },
    }
}

pub fn gameStageOnTimeTickFunction() void {
    if (gameStage.pauseMovement) {
        gameStage.haltTime += 1;

        if (gameStage.haltTime == 2) {
            gameStage.pauseMovement = false;
            gameStage.haltTime = 0;

            if (player.player.currentMovement == player.PLAYER_UP or player.player.currentMovement == player.PLAYER_COMING_DOWN) {
                player.player.activateAttack = true;
                player.player.activateTime = 0;
                player.player.showHit = false;
            }

            gameStage.villainHealth -= 1;
            if (gameStage.villainHealth == 0) {
                ray.StopMusicStream(global.musics[0]);
                gameStage.haltTime = 0;
            } else {
                if (gameStage.villainMoveState != MOVE_STATE_RUNNING_LEFT and gameStage.villainMoveState != MOVE_STATE_RUNNING_RIGHT) {
                    gameStage.runCounter = 0;
                    gameStage.villainMoveState = if (!gameStage.isVillainFlipped) MOVE_STATE_RUNNING_RIGHT else MOVE_STATE_RUNNING_LEFT;

                    const str_spr = std.fmt.allocPrint(std.heap.page_allocator, "{s}_normal", .{Villains[global.stage - 1]}) catch |err| {
                        std.debug.print("Error on str_spr: {}\n", .{err});
                        return;
                    };

                    global.sprites[global.findSpriteImagesIndex(str_spr)].frameSpeed = VILLAIN_SPRITE_FRAME_SPEED_RUN;
                }
            }
        }
    }

    if (gameStage.villainHealth == 0) {
        gameStage.haltTime += 1;
        if (gameStage.haltTime == gameStage.maxHaltTime) {
            gameStageHandleEndState();
            gameStage.haltTime = 0;
        }
    }

    if (player.player.health == 0 and gameStage.villainHealth != 0) {
        gameStage.haltTime += 1;
        if (gameStage.haltTime == gameStage.maxHaltTime) {
            gameStageHandleVillainEndState();
            gameStage.haltTime = 0;
        }
    }

    if (gameStage.showVillainHit) {
        gameStage.haltTimeHit += 1;
        if (gameStage.haltTimeHit == 4) {
            gameStage.haltTimeHit = 0;
            gameStage.showVillainHit = false;
            gameStageResetVillainMove();

            player.player.x = player.player.oldX;
            player.player.shake = false;

            if ((player.player.currentMovement == player.PLAYER_RIGHT and !(ray.IsKeyDown(ray.KEY_RIGHT) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_RIGHT)))) or (player.player.currentMovement == player.PLAYER_LEFT and !(ray.IsKeyDown(ray.KEY_LEFT) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_LEFT)))) or (player.player.currentMovement == player.PLAYER_DOWN and !(ray.IsKeyDown(ray.KEY_DOWN) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_DOWN))))) {
                try player.player.setMovement(player.PLAYER_IDLE);
            }

            if (player.player.health == 0) {
                gameStage.villainCurrentMove = VILLAIN_MOVE_PAUSE;
            }
        }
    }
}

pub fn gameStageOnHandleKeysFunction() void {
    if (player.player.health > 0 and gameStage.villainHealth > 0)
        player.player.handleKeys();

    if (((gameStage.endState == END_STATE_GAME_OVER) or (gameStage.villainEndState == END_STATE_VILLAIN_GAME_OVER)) and (ray.IsKeyDown(ray.KEY_ENTER) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_MIDDLE_RIGHT)))) {
        gameStageCleanUpFunction();
        global.state = global.GameState.STAGE_START;
        global.stage = 1;
        global.score = 0;
        titleStage.canEnter = false;
        player.player.lives = player.PLAYER_DEFAULT_LIVES;
    }
}

pub fn gameStageCleanUpFunction() void {
    gameStageReset();
    try player.player.clear();
    try gameStage.cleanUp();
}

pub fn gameStageOnBlinkingDoneFunction() void {
    // blank for now
}

pub fn gameStageOnRunFunction() void {
    if (!gameStage.pauseMovement) {
        try player.player.timeTick(player.playerOnTimeTickFunction);
        player.player.handleJump();
    }

    if (!player.player.showHit and gameStage.villainHealth > 0 and player.player.health > 0)
        gameStageVillainMovementTick();
}

pub fn gameStageSetVillainSpritesCoordinates() void {
    for (VillainSprites) |vSprite| {
        const str_spr = std.fmt.allocPrint(std.heap.page_allocator, "{s}_{s}", .{ Villains[global.stage - 1], vSprite }) catch |err| {
            std.debug.print("Error on str_spr: {}\n", .{err});
            return;
        };

        if (std.mem.eql(u8, vSprite, "hit") or std.mem.eql(u8, vSprite, "other") or std.mem.eql(u8, vSprite, "kick"))
            continue;

        global.sprites[global.findSpriteImagesIndex(str_spr)].x = gameStage.villainX;
        global.sprites[global.findSpriteImagesIndex(str_spr)].y = gameStage.villainY;
    }
}

pub fn gameStageFlipVillainSprites() void {
    for (VillainSprites) |vSprite| {
        const str_spr = std.fmt.allocPrint(std.heap.page_allocator, "{s}_{s}", .{ Villains[global.stage - 1], vSprite }) catch |err| {
            std.debug.print("Error on str_spr: {}\n", .{err});
            return;
        };
        try global.sprites[global.findSpriteImagesIndex(str_spr)].flipHorizontal();
    }

    try global.sprites[global.findSpriteImagesIndex("spinning_chain")].flipHorizontal();

    gameStage.isVillainFlipped = !gameStage.isVillainFlipped;

    if (gameStage.isVillainFlipped) {
        gameStage.spinningChainX -= 19;
        return;
    }

    gameStage.spinningChainX += 19;
}

pub fn gameStageCheckCollisionWithPlayer(vX: *i16, vY: *i16, vBoxWidth: *i16, vBoxHeight: *i16, collisionInfo: [5]global.CollisionInfo) void {
    vX.* = if (gameStage.isVillainFlipped) ((gameStage.villainX - collisionsInfo[global.stage - 1].minusXKick) + collisionInfo[global.stage - 1].x2) else ((gameStage.villainX - collisionsInfo[global.stage - 1].minusXKick) + collisionInfo[global.stage - 1].x1);
    vY.* = (gameStage.villainY + collisionInfo[global.stage - 1].y);
    vBoxWidth.* = @intCast(collisionInfo[global.stage - 1].width);
    vBoxHeight.* = @intCast(collisionInfo[global.stage - 1].height);
}

pub fn gameStageIsCollidedWithPlayer() bool {
    const pX = if (player.player.isFlipped) (player.player.x + player.playerCollisionInfo.x2) else (player.player.x + player.playerCollisionInfo.x1);
    const pY = (player.player.y + player.playerCollisionInfo.y);
    const lowerX1 = pX + player.playerCollisionInfo.width - 1;
    const lowerY1 = pY + player.playerCollisionInfo.height - 1;

    var lowerX2: i16 = 0;
    var lowerY2: i16 = 0;
    var vX: i16 = 0;
    var vY: i16 = 0;
    var vBoxWidth: i16 = 0;
    var vBoxHeight: i16 = 0;

    switch (gameStage.villainCurrentMove) {
        VILLAIN_MOVE_KICK => {
            gameStageCheckCollisionWithPlayer(&vX, &vY, &vBoxWidth, &vBoxHeight, collisionsKickInfo);
        },
        VILLAIN_MOVE_OTHER => {
            gameStageCheckCollisionWithPlayer(&vX, &vY, &vBoxWidth, &vBoxHeight, collisionsOtherInfo);
        },
        else => {
            //VILLAIN_MOVE_SPECIAL
        },
    }

    lowerX2 = vX + vBoxWidth - 1;
    lowerY2 = vY + vBoxHeight - 1;

    if (lowerX1 < vX or player.player.x > lowerX2 or lowerY1 < vY or player.player.y > lowerY2) {
        return false;
    }

    const str_spr = std.fmt.allocPrint(std.heap.page_allocator, "{s}_hit", .{Villains[global.stage - 1]}) catch |err| {
        std.debug.print("Error on str_spr: {}\n", .{err});
        return false;
    };

    // collided
    global.sprites[global.findSpriteImagesIndex(str_spr)].x = vX;
    global.sprites[global.findSpriteImagesIndex(str_spr)].y = vY;
    return true;
}

pub fn gameStageResetVillainMove() void {
    gameStage.villainCurrentMove = VILLAIN_MOVE_IDLE;
    gameStage.villainMoveState = MOVE_STATE_FOLLOW_PLAYER;
    const str_spr = std.fmt.allocPrint(std.heap.page_allocator, "{s}_{s}", .{ Villains[global.stage - 1], VillainSprites[gameStage.villainRandomAttack] }) catch |err| {
        std.debug.print("Error on str_spr: {}\n", .{err});
        return;
    };
    global.sprites[global.findSpriteImagesIndex(str_spr)].resetCurrentFrame();
}

pub fn gameStageHandleCollisionWithPlayer() void {
    gameStage.villainCurrentMove = VILLAIN_MOVE_PAUSE;
    gameStage.showVillainHit = true;
    ray.PlaySound(global.sounds[6]); //collided2
    gameStage.haltTimeHit = 0;

    player.player.oldX = player.player.x;
    player.player.shake = true;
    player.player.addX = true;

    player.player.health -= 1;

    if (player.player.health == global.LOW_HEALTH) {
        ray.PlaySound(global.sounds[8]); //low_health
    }

    if (!gameStage.isVillainFlipped) {
        gameStageVillainModifyX(VILLAIN_FB_SPEED, true);
        return;
    }
    gameStageVillainModifyX(VILLAIN_FB_SPEED, false);
}

pub fn gameStageVillainModifyX(amount: i16, isAdd: bool) void {
    gameStage.villainX = if (isAdd) gameStage.villainX + amount else gameStage.villainX - amount;
    if (global.stage == 3)
        gameStage.spinningChainX = if (isAdd) gameStage.spinningChainX + amount else gameStage.spinningChainX - amount;
}

pub fn gameStageShowVillain() void {
    gameStageSetVillainSpritesCoordinates();
    switch (gameStage.villainCurrentMove) {
        VILLAIN_MOVE_LEFT => {
            // nothing to do
        },
        VILLAIN_MOVE_DEAD => {
            const str_spr = std.fmt.allocPrint(std.heap.page_allocator, "{s}_dead", .{Villains[global.stage - 1]}) catch |err| {
                std.debug.print("Error on str_spr: {}\n", .{err});
                return;
            };
            try global.sprites[global.findSpriteImagesIndex(str_spr)].draw();
        },
        VILLAIN_MOVE_KICK, VILLAIN_MOVE_OTHER => {
            const str_spr = std.fmt.allocPrint(std.heap.page_allocator, "{s}_{s}", .{ Villains[global.stage - 1], VillainSprites[gameStage.villainRandomAttack] }) catch |err| {
                std.debug.print("Error on str_spr: {}\n", .{err});
                return;
            };

            global.sprites[global.findSpriteImagesIndex(str_spr)].y = gameStage.villainY;
            global.sprites[global.findSpriteImagesIndex(str_spr)].x = gameStage.villainX - collisionsInfo[global.stage - 1].minusXKick;
            global.sprites[global.findSpriteImagesIndex(str_spr)].paused = player.player.showHit;

            if (global.sprites[global.findSpriteImagesIndex(str_spr)].play()) // if last frame
            {
                if (!gameStageIsCollidedWithPlayer()) {
                    gameStageResetVillainMove();
                }
                if (gameStageIsCollidedWithPlayer() and player.player.health > 0) {
                    // collision with player
                    gameStageHandleCollisionWithPlayer();
                }
            }
        },
        VILLAIN_MOVE_PAUSE => {
            const str_spr = std.fmt.allocPrint(std.heap.page_allocator, "{s}_{s}", .{ Villains[global.stage - 1], VillainSprites[gameStage.villainRandomAttack] }) catch |err| {
                std.debug.print("Error on str_spr: {}\n", .{err});
                return;
            };
            try global.sprites[global.findSpriteImagesIndex(str_spr)].drawByIndex(1);
        },
        else => {
            // VILLAIN_MOVE_IDLE
            if (global.stage == 3) {
                global.sprites[global.findSpriteImagesIndex("spinning_chain")].x = gameStage.spinningChainX;
                global.sprites[global.findSpriteImagesIndex("spinning_chain")].y = gameStage.spinningChainY;
                global.sprites[global.findSpriteImagesIndex("spinning_chain")].paused = player.player.showHit;
                _ = global.sprites[global.findSpriteImagesIndex("spinning_chain")].play();
            }

            const str_spr = std.fmt.allocPrint(std.heap.page_allocator, "{s}_normal", .{Villains[global.stage - 1]}) catch |err| {
                std.debug.print("Error on str_spr: {}\n", .{err});
                return;
            };

            global.sprites[global.findSpriteImagesIndex(str_spr)].paused = player.player.showHit;
            _ = global.sprites[global.findSpriteImagesIndex(str_spr)].play();
        },
    }

    //flip checker
    if ((player.player.x) > gameStage.villainX and !gameStage.isVillainFlipped and gameStage.villainCurrentMove != VILLAIN_MOVE_KICK and gameStage.villainCurrentMove != VILLAIN_MOVE_OTHER) {
        gameStageFlipVillainSprites();
    }
    if ((gameStage.villainX) > player.player.x and gameStage.isVillainFlipped and gameStage.villainCurrentMove != VILLAIN_MOVE_KICK and gameStage.villainCurrentMove != VILLAIN_MOVE_OTHER) {
        gameStageFlipVillainSprites();
    }
}
