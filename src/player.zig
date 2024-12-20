const std = @import("std");
const global = @import("global.zig");
const stage = @import("stage.zig");
const ray = @cImport({
    @cInclude("raylib.h");
});

pub const PLAYER_NONE = -1;
pub const PLAYER_IDLE = 0;
pub const PLAYER_IDLE_2 = 1;
pub const PLAYER_LEFT = 2;
pub const PLAYER_RIGHT = 3;
pub const PLAYER_DOWN = 4;
pub const PLAYER_STAND_PUNCH = 5;
pub const PLAYER_SIT_PUNCH = 6;
pub const PLAYER_STAND_KICK = 7;
pub const PLAYER_SIT_KICK = 8;
pub const PLAYER_HIGH_KICK = 9;
pub const PLAYER_UP = 10;
pub const PLAYER_COMING_DOWN = 11;
pub const PLAYER_SMILE = 12;
pub const PLAYER_DEAD = 13;
pub const PLAYER_VERY_DEAD = 14;
pub const PLAYER_SPEED = 1;
pub const PLAYER_FRAME_SPEED = 15;
pub const PLAYER_DEFAULT_X = 40;
pub const PLAYER_DEFAULT_Y = 159;
pub const PLAYER_DEFAULT_LIVES = 2;
pub const PLAYER_JUMP_HEIGHT = 115;
pub const PLAYER_JUMP_SPEED = 2;
pub const PLAYER_JUMP_ACCELERATION_FRAME_SPEED = 55;
pub const PLAYER_JUMP_TOWARDS_NONE = 0;
pub const PLAYER_JUMP_TOWARDS_LEFT = 1;
pub const PLAYER_JUMP_TOWARDS_RIGHT = 2;
pub const PLAYER_SHAKE_FORCE = 2;
pub const PLAYER_CAN_ATTACK_TIME = 2;

pub const PlayerSprites = [_][]const u8{
    "player_normal",
    "player_down",
    "player_stand_punch",
    "player_sit_punch",
    "player_stand_kick",
    "player_sit_kick",
    "player_high_kick",
    "player_flying_kick",
    "player_smile",
    "player_dead",
};

pub const collisionInfoSitPunch = global.CollisionInfo{
    .x1 = 28,
    .x2 = 0,
    .y = 19,
    .width = 3,
    .height = 3,
    .minusXKick = 0,
};

pub const collisionInfoStandKick = global.CollisionInfo{
    .x1 = 25,
    .x2 = 0,
    .y = 24,
    .width = 6,
    .height = 5,
    .minusXKick = 0,
};

pub const collisionInfoSitKick = global.CollisionInfo{
    .x1 = 30,
    .x2 = 0,
    .y = 27,
    .width = 6,
    .height = 5,
    .minusXKick = 0,
};

pub const collisionInfoHighKick = global.CollisionInfo{
    .x1 = 27,
    .x2 = 0,
    .y = 3,
    .width = 5,
    .height = 4,
    .minusXKick = 0,
};

pub const collisionInfoAir = global.CollisionInfo{
    .x1 = 31,
    .x2 = 0,
    .y = 24,
    .width = 4,
    .height = 5,
    .minusXKick = 0,
};

pub const collisionInfoStandPunch = global.CollisionInfo{
    .x1 = 25,
    .x2 = 0,
    .y = 14,
    .width = 3,
    .height = 3,
    .minusXKick = 0,
};

pub const playerCollisionInfo = global.CollisionInfo{
    .x1 = 8,
    .x2 = 10,
    .y = 1,
    .width = 10,
    .height = 32,
    .minusXKick = 0,
};

const Player = struct {
    timeCounter: u16 = 0,
    timeSeconds: u16 = 0,
    haltTime: u16,
    haltTimeJump: u16,
    lastMovement: i16,
    jumpFramesCounter: u16 = 0,
    accelerationSpeed: u16 = 0,
    jumpTowards: u16,
    isFlyingKick: bool = false,
    canFlyingKick: bool = true,
    isFlipped: bool = false,
    x: i16,
    y: i16,
    lives: u8,
    health: u8,
    currentMovement: i16,
    inputDisabled: bool,
    canAttack: bool,
    activateAttack: bool,
    activateTime: u8 = 0,
    oldX: i16 = 0,
    shake: bool = false,
    addX: bool = true,
    kuyakoy: u8 = 0,
    showHit: bool = false,

    pub fn setMovement(self: *Player, move: i16) !void {
        if (self.currentMovement == PLAYER_DEAD and move == PLAYER_IDLE) {
            return;
        }
        self.lastMovement = self.currentMovement;
        self.currentMovement = move;
    }

    pub fn clear(self: *Player) !void {
        try self.setMovement(PLAYER_IDLE);
        self.x = PLAYER_DEFAULT_X;
        self.y = PLAYER_DEFAULT_Y;
        self.inputDisabled = false;
        self.haltTime = 0;
        self.haltTimeJump = 0;
        self.canAttack = true;
        self.activateAttack = false;
        self.lastMovement = PLAYER_NONE;
        self.health = global.DEFAULT_HEALTH;

        if (self.isFlipped) {
            try self.flipSprites();
        }
    }

    pub fn new(self: *Player) !void {
        self.lives = PLAYER_DEFAULT_LIVES;
        try self.clear();

        global.sprites[global.findSpriteImagesIndex("player_normal")].frameSpeed = PLAYER_FRAME_SPEED;
    }

    pub fn flipSprites(self: *Player) !void {
        for (PlayerSprites) |name| {
            try global.sprites[global.findSpriteImagesIndex(name)].flipHorizontal();
        }
        try global.sprites[global.findSpriteImagesIndex("hit")].flipHorizontal();
        self.isFlipped = !self.isFlipped;
    }

    pub fn setSpritesCoordinates(self: *Player) !void {
        for (PlayerSprites) |name| {
            global.sprites[global.findSpriteImagesIndex(name)].x = self.x;
            global.sprites[global.findSpriteImagesIndex(name)].y = self.y;
        }
    }

    pub fn timeTick(self: *Player, onTimeTickFunction: global.voidFunc) !void {
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

    pub fn play(self: *Player) !void {
        if (self.shake) {
            self.x = if (self.addX) self.x + PLAYER_SHAKE_FORCE else self.x - PLAYER_SHAKE_FORCE;
            self.addX = !self.addX;
        }

        try self.setSpritesCoordinates();

        switch (self.currentMovement) {
            PLAYER_LEFT, PLAYER_RIGHT => {
                global.sprites[global.findSpriteImagesIndex("player_normal")].paused = stage.gameStage.showVillainHit;
                _ = global.sprites[global.findSpriteImagesIndex("player_normal")].play();
            },
            PLAYER_DOWN, PLAYER_UP, PLAYER_COMING_DOWN => {
                if (self.isFlyingKick) try global.sprites[global.findSpriteImagesIndex("player_flying_kick")].draw() else try global.sprites[global.findSpriteImagesIndex("player_down")].draw();
            },
            PLAYER_IDLE_2 => {
                try global.sprites[global.findSpriteImagesIndex("player_normal")].drawByIndex(1);
            },
            PLAYER_STAND_PUNCH => {
                try global.sprites[global.findSpriteImagesIndex("player_stand_punch")].draw();
            },
            PLAYER_SIT_PUNCH => {
                try global.sprites[global.findSpriteImagesIndex("player_sit_punch")].draw();
            },
            PLAYER_STAND_KICK => {
                try global.sprites[global.findSpriteImagesIndex("player_stand_kick")].draw();
            },
            PLAYER_SIT_KICK => {
                try global.sprites[global.findSpriteImagesIndex("player_sit_kick")].draw();
            },
            PLAYER_HIGH_KICK => {
                try global.sprites[global.findSpriteImagesIndex("player_high_kick")].draw();
            },
            PLAYER_SMILE => {
                try global.sprites[global.findSpriteImagesIndex("player_smile")].draw();
            },
            PLAYER_VERY_DEAD => {
                try global.sprites[global.findSpriteImagesIndex("player_dead")].draw();
            },
            PLAYER_DEAD => {
                if (global.sprites[global.findSpriteImagesIndex("player_dead")].play()) {
                    ray.PlaySound(global.sounds[7]); // feet_sound
                    self.kuyakoy += 1;

                    if (self.kuyakoy == 3) {
                        try self.setMovement(PLAYER_VERY_DEAD);
                        stage.gameStage.villainEndState = stage.END_STATE_VILLAIN_END;
                    }
                }
            },
            else => {
                try global.sprites[global.findSpriteImagesIndex("player_normal")].drawByIndex(0);
            },
        }

        if (self.showHit) {
            try global.sprites[global.findSpriteImagesIndex("hit")].draw();
        }

        //flip checker
        if (stage.gameStage.endState <= stage.END_STATE_START) {
            if ((stage.gameStage.villainX) < self.x and !self.isFlipped and !self.isFlyingKick) {
                try self.flipSprites();
            }
            if ((self.x) < stage.gameStage.villainX and self.isFlipped and !self.isFlyingKick) {
                try self.flipSprites();
            }
        }
    }

    pub fn checkCollisionWithVillain(self: *Player, playerX: *i16, playerY: *i16, playerBoxWidth: *i16, playerBoxHeight: *i16, collisionInfo: global.CollisionInfo) void {
        playerX.* = if (self.isFlipped) self.x else (self.x + collisionInfo.x1);
        playerY.* = (self.y + collisionInfo.y);
        playerBoxWidth.* = @intCast(collisionInfo.width);
        playerBoxHeight.* = @intCast(collisionInfo.height);
    }

    pub fn isCollidedWithVillain(self: *Player) void {
        const villainX = if (stage.gameStage.isVillainFlipped) (stage.gameStage.villainX + stage.collisionsInfo[global.stage - 1].x2) else (stage.gameStage.villainX + stage.collisionsInfo[global.stage - 1].x1);
        const villainY = (stage.gameStage.villainY + stage.collisionsInfo[global.stage - 1].y);
        const icw: i16 = @intCast(stage.collisionsInfo[global.stage - 1].width);
        const ich: i16 = @intCast(stage.collisionsInfo[global.stage - 1].height);
        const lowerX1 = villainX + icw - 1;
        const lowerY1 = villainY + ich - 1;

        var lowerX2: i16 = 0;
        var lowerY2: i16 = 0;
        var playerX: i16 = 0;
        var playerY: i16 = 0;
        var playerBoxWidth: i16 = 0;
        var playerBoxHeight: i16 = 0;
        var scoreToAdd: u32 = 100;

        switch (self.currentMovement) {
            PLAYER_SIT_PUNCH => {
                self.checkCollisionWithVillain(&playerX, &playerY, &playerBoxWidth, &playerBoxHeight, collisionInfoSitPunch);
            },
            PLAYER_STAND_KICK => {
                self.checkCollisionWithVillain(&playerX, &playerY, &playerBoxWidth, &playerBoxHeight, collisionInfoStandKick);
            },
            PLAYER_SIT_KICK => {
                self.checkCollisionWithVillain(&playerX, &playerY, &playerBoxWidth, &playerBoxHeight, collisionInfoSitKick);
            },
            PLAYER_HIGH_KICK => {
                self.checkCollisionWithVillain(&playerX, &playerY, &playerBoxWidth, &playerBoxHeight, collisionInfoHighKick);
                scoreToAdd = 200;
            },
            PLAYER_UP, PLAYER_COMING_DOWN => {
                self.checkCollisionWithVillain(&playerX, &playerY, &playerBoxWidth, &playerBoxHeight, collisionInfoAir);
                scoreToAdd = 300;
            },
            else => {
                //PLAYER_STAND_PUNCH
                self.checkCollisionWithVillain(&playerX, &playerY, &playerBoxWidth, &playerBoxHeight, collisionInfoStandPunch);
            },
        }

        lowerX2 = playerX + playerBoxWidth - 1;
        lowerY2 = playerY + playerBoxHeight - 1;

        if (lowerX1 < playerX or villainX > lowerX2 or lowerY1 < playerY or villainY > lowerY2) {
            ray.PlaySound(global.sounds[0]); //attack
            return;
        }

        // collided
        ray.PlaySound(global.sounds[1]); //collided
        global.sprites[global.findSpriteImagesIndex("hit")].x = playerX;
        global.sprites[global.findSpriteImagesIndex("hit")].y = playerY;
        stage.gameStage.haltTime = 0;
        stage.gameStage.pauseMovement = true;
        global.score += scoreToAdd;
        self.showHit = true;
    }

    pub fn handleAttack(self: *Player, condition: bool, movement: i16) void {
        if (condition) {
            self.inputDisabled = true;
            self.canAttack = false;
            try self.setMovement(movement);
            self.isCollidedWithVillain();
        }
    }

    pub fn handleKeys(self: *Player) void {
        // making sure that it will be executed only on a specific state
        if (global.state == global.GameState.STAGE_GAME and !self.inputDisabled and !stage.gameStage.pauseMovement and !stage.gameStage.showVillainHit) {
            const w = @as(i16, @intCast(global.sprites[global.findSpriteImagesIndex("player_normal")].texture.width));
            if ((ray.IsKeyDown(ray.KEY_LEFT) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_LEFT))) and self.x > global.STAGE_BOUNDARY) {
                try self.setMovement(PLAYER_LEFT);
                self.x -= PLAYER_SPEED;
            } else if ((ray.IsKeyDown(ray.KEY_LEFT) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_LEFT))) and self.x <= global.STAGE_BOUNDARY) {
                try self.setMovement(PLAYER_IDLE);
            } else if ((ray.IsKeyReleased(ray.KEY_LEFT) or (ray.IsGamepadButtonReleased(0, ray.GAMEPAD_BUTTON_LEFT_FACE_LEFT) and ray.IsGamepadAvailable(0)))) {
                try self.setMovement(PLAYER_IDLE);
            } else if ((ray.IsKeyDown(ray.KEY_RIGHT) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_RIGHT))) and self.x < (global.GAME_WIDTH - global.STAGE_BOUNDARY - @divTrunc(w, 2))) {
                try self.setMovement(PLAYER_RIGHT);
                self.x += PLAYER_SPEED;
            } else if ((ray.IsKeyDown(ray.KEY_RIGHT) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_RIGHT))) and self.x >= (global.GAME_WIDTH - global.STAGE_BOUNDARY - @divTrunc(w, 2))) {
                try self.setMovement(PLAYER_IDLE_2);
            } else if ((ray.IsKeyReleased(ray.KEY_RIGHT) or (ray.IsGamepadButtonReleased(0, ray.GAMEPAD_BUTTON_LEFT_FACE_RIGHT) and ray.IsGamepadAvailable(0)))) {
                try self.setMovement(PLAYER_IDLE);
            } else if ((ray.IsKeyDown(ray.KEY_DOWN) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_DOWN)))) {
                try self.setMovement(PLAYER_DOWN);
            } else if ((ray.IsKeyReleased(ray.KEY_DOWN) or (ray.IsGamepadButtonReleased(0, ray.GAMEPAD_BUTTON_LEFT_FACE_DOWN) and ray.IsGamepadAvailable(0)))) {
                try self.setMovement(PLAYER_IDLE);
            }

            if ((ray.IsKeyDown(ray.KEY_UP) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_UP)))) {
                self.jumpTowards = PLAYER_JUMP_TOWARDS_NONE;

                if ((ray.IsKeyDown(ray.KEY_LEFT) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_LEFT)))) {
                    self.jumpTowards = PLAYER_JUMP_TOWARDS_LEFT;
                }

                if ((ray.IsKeyDown(ray.KEY_RIGHT) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_RIGHT)))) {
                    self.jumpTowards = PLAYER_JUMP_TOWARDS_RIGHT;
                }

                try self.setMovement(PLAYER_UP);
                self.inputDisabled = true;
                self.accelerationSpeed = PLAYER_JUMP_ACCELERATION_FRAME_SPEED;
            }

            self.handleAttack(((ray.IsKeyDown(ray.KEY_A) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_RIGHT_FACE_LEFT))) and self.canAttack), (if ((ray.IsKeyDown(ray.KEY_DOWN) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_DOWN)))) PLAYER_SIT_PUNCH else PLAYER_STAND_PUNCH));

            self.handleAttack(((ray.IsKeyDown(ray.KEY_S) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_RIGHT_FACE_DOWN))) and self.canAttack and ((ray.IsKeyDown(ray.KEY_LEFT) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_LEFT))) or (ray.IsKeyDown(ray.KEY_RIGHT) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_RIGHT))))), PLAYER_HIGH_KICK);

            self.handleAttack(((ray.IsKeyDown(ray.KEY_S) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_RIGHT_FACE_DOWN))) and self.canAttack), (if ((ray.IsKeyDown(ray.KEY_DOWN) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_DOWN)))) PLAYER_SIT_KICK else PLAYER_STAND_KICK));
        }

        if (global.state == global.GameState.STAGE_GAME and ((ray.IsKeyReleased(ray.KEY_A) or (ray.IsGamepadButtonReleased(0, ray.GAMEPAD_BUTTON_RIGHT_FACE_LEFT) and ray.IsGamepadAvailable(0))) or (ray.IsKeyReleased(ray.KEY_S) or (ray.IsGamepadButtonReleased(0, ray.GAMEPAD_BUTTON_RIGHT_FACE_DOWN) and ray.IsGamepadAvailable(0)))) and !self.activateAttack and !self.showHit) {
            self.activateAttack = true;
            self.activateTime = 0;
        }

        if (global.state == global.GameState.STAGE_GAME and (ray.IsKeyDown(ray.KEY_S) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_RIGHT_FACE_DOWN))) and !self.isFlyingKick and (self.currentMovement == PLAYER_UP or self.currentMovement == PLAYER_COMING_DOWN) and self.y <= (PLAYER_JUMP_HEIGHT + 24) // TODO: Not sure if it is the right Math (16 ORIGINALY)
        and self.canFlyingKick and !stage.gameStage.pauseMovement and !stage.gameStage.showVillainHit) {
            self.isFlyingKick = true;
            self.haltTimeJump = 0;
            self.canFlyingKick = false;
            self.isCollidedWithVillain();
        }
    }

    pub fn handleTowardsJump(self: *Player) void {
        const w = @as(i16, @intCast(global.sprites[global.findSpriteImagesIndex("player_normal")].texture.width));
        if (self.jumpTowards == PLAYER_JUMP_TOWARDS_RIGHT) {
            if (self.x < (global.GAME_WIDTH - global.STAGE_BOUNDARY - @divTrunc(w, 2))) {
                self.x += PLAYER_JUMP_SPEED;
                return;
            }

            self.x = (global.GAME_WIDTH - global.STAGE_BOUNDARY - @divTrunc(w, 2));
            self.jumpTowards = PLAYER_JUMP_TOWARDS_LEFT;
            return;
        }

        if (self.jumpTowards == PLAYER_JUMP_TOWARDS_LEFT) {
            if (self.x > global.STAGE_BOUNDARY) {
                self.x -= PLAYER_JUMP_SPEED;
                return;
            }

            self.x = global.STAGE_BOUNDARY;
            self.jumpTowards = PLAYER_JUMP_TOWARDS_RIGHT;
        }
    }

    pub fn handleJump(self: *Player) void {
        if ((self.currentMovement == PLAYER_UP or self.currentMovement == PLAYER_COMING_DOWN) and !stage.gameStage.showVillainHit and self.health > 0) {
            self.jumpFramesCounter += 1;
            if (self.jumpFramesCounter >= (global.TARGET_FPS / self.accelerationSpeed)) {
                self.jumpFramesCounter = 0;
                self.handleTowardsJump();

                if (self.currentMovement == PLAYER_UP) {
                    if (self.y > PLAYER_JUMP_HEIGHT) {
                        self.accelerationSpeed -= 1;
                        self.y -= PLAYER_JUMP_SPEED;
                        return;
                    }
                    try self.setMovement(PLAYER_COMING_DOWN);
                    return;
                }

                if (self.y < PLAYER_DEFAULT_Y) {
                    if (self.accelerationSpeed < PLAYER_JUMP_ACCELERATION_FRAME_SPEED) {
                        self.accelerationSpeed += 1;
                    }
                    self.y += PLAYER_JUMP_SPEED;
                    return;
                }

                self.y = PLAYER_DEFAULT_Y;
                try self.setMovement(PLAYER_IDLE);
                self.isFlyingKick = false;
                self.inputDisabled = false;
                self.canFlyingKick = true;
            }
        }
    }
};

pub var player = Player{
    .haltTime = 0,
    .haltTimeJump = 0,
    .lastMovement = PLAYER_NONE,
    .jumpTowards = PLAYER_JUMP_TOWARDS_NONE,
    .x = PLAYER_DEFAULT_X,
    .y = PLAYER_DEFAULT_Y,
    .lives = PLAYER_DEFAULT_LIVES,
    .health = global.DEFAULT_HEALTH,
    .currentMovement = PLAYER_NONE,
    .inputDisabled = false,
    .canAttack = true,
    .activateAttack = false,
};

pub fn playerOnTimeTickFunction() void {
    if (player.inputDisabled and player.currentMovement != PLAYER_UP and player.currentMovement != PLAYER_COMING_DOWN and !stage.gameStage.showVillainHit) {
        player.haltTime += 1;

        if (player.haltTime == 3) {
            player.inputDisabled = false;
            player.haltTime = 0;
            player.showHit = false;
            player.activateAttack = true;
            player.activateTime = 0;

            if (player.lastMovement == PLAYER_DOWN and (ray.IsKeyDown(ray.KEY_DOWN) or (ray.IsGamepadAvailable(0) and ray.IsGamepadButtonDown(0, ray.GAMEPAD_BUTTON_LEFT_FACE_DOWN)))) {
                try player.setMovement(PLAYER_DOWN);
                return;
            }

            try player.setMovement(PLAYER_IDLE);
        }
    }

    if (player.inputDisabled and player.isFlyingKick and !stage.gameStage.showVillainHit) {
        player.haltTimeJump += 1;

        if (player.haltTimeJump == 2) {
            player.haltTimeJump = 0;
            player.isFlyingKick = false;
        }
    }

    if (player.activateAttack) {
        player.activateTime += 1;
        if (player.activateTime == PLAYER_CAN_ATTACK_TIME) {
            player.activateTime = 0;
            player.canAttack = true;
            player.activateAttack = false;
        }
    }
}
