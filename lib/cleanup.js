//
// cleanup.js
//
// This file is converted from a post in stackoverflow by CanyonCasa.
// URL:
// http://stackoverflow.com/questions/14031763/doing-a-cleanup-action-just-before-node-js-exits
//

// Register cleanup function.
module.exports = function(callback) {
    if (callback) {
        process.on("cleanup", callback);
        process.on("exit", () => {
            process.emit("cleanup");
        });
    }
    process.on("SIGINT", () => {
        console.log("Ctrl-C...");
        process.exit(2);
    });
    process.on("uncaughtException", (e) => {
        console.log("Uncaught Exception...");
        console.error(e.stack);
        process.exit(99);
    });
};
