const path = require('path');
const fs = require('fs');

const imageDirectory = path.join(__dirname, "../img");
const imageListFile = path.join(__dirname, "../src/turboman_images.js")
const imageExt = "jpg";

fs.readdir(imageDirectory, function(err, files) {
    if (err) {
        return console.log("Error: "+err);
    }

    imageList = [];

    files.forEach(function (f) {
        imageList.push(f)
    });

    yearStart = imageList[0]+"";
    yearEnd = imageList[imageList.length-1]+"";

    outputCode = "const startYear = "+yearStart.replace("."+imageExt, "")+";\n";
    outputCode = outputCode+"const endYear = "+yearEnd.replace("."+imageExt,"")+";\n";
    outputCode = outputCode+"const imageExt = \""+imageExt+"\";\n";

    fs.writeFileSync(imageListFile, outputCode);
})