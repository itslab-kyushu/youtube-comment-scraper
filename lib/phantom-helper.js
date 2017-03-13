//
// phantom-helper.js
//
// Copyright (c) 2016-2017 Junpei Kawamoto
//
// This software is released under the MIT License.
//
// http://opensource.org/licenses/mit-license.php
//

// Ensure creating only one PhantomJS instance.
// This module exports two functions, get and close. get function returns an
// instance of PhantomJS. This function ensures to make only one instance and
// reuse it. close function close the connection to the created instance and
// delete it.
const phantom = require("phantom");
const cleanup = require("./cleanup");
let phantom_instance = null;
let locked = false;

module.exports = {

    // Get an instance of PhantomJS.
    // If there are no instances, this function creates it.
    get() {
        return new Promise((resolve) => {

            // Creates an instance of PhantomJS if there are no instance created.
            // and returns it. Otherwise, returns the existing instance.
            function get_or_create() {
                if (locked) {
                    setTimeout(wait, 100);
                } else {
                    locked = true;

                    if (phantom_instance != null) {
                        locked = false;
                        resolve(phantom_instance);
                    } else {
                        phantom.create().then((instance) => {
                            phantom_instance = instance;
                            locked = false;
                            resolve(instance);
                        });
                    }
                }
            }
            get_or_create();
        });
    },

    // Delete PhantomJS instance.
    // It is safe to call this method many times.
    close() {
        if (phantom_instance != null) {
            phantom_instance.exit();
            phantom_instance = null;
        }
    }
};

// Register close function as a cleanup function.
cleanup(module.exports.close);
