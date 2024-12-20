//!Build with zig build-exe main.zig --name kungfu -I /opt/homebrew/Cellar/raylib/5.5/include -L /opt/homebrew/Cellar/raylib/5.5/lib/ -lc -lraylib
const game = @import("game.zig");
pub fn main() !u8 {
    try game.init();
    try game.run();
    return 0;
}
