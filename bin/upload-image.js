const fs = require("fs")
const AWS = require('aws-sdk');

const bucketPath

const main = (imgPath) => {
    fs.stat(imgPath, function(err, stats) {
        if (!stats.isDirectory()) {
            throw new Error(`"${imgPath}" is not a directory.`)
        }
    })

    fs.readdir(imgPath, (err, files) => {
        files.forEach(file => {
            console.log(file);
        });
    });
}

main(process.env.IMGPATH)
