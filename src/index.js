const startYear = 2013
const endYear = 2020
const imageExt = "jpg"

const loadImage = () => {
    let c = document.getElementById("theCanvas");
    let ctx = c.getContext("2d");
    let img = new Image()

    img.onload = () => {
        let scale = Math.min(c.width, c.height) / Math.max(img.width, img.height)
        let x = (c.width / 2) - (img.width / 2) * scale
        let y = (c.height / 2) - (img.height / 2) * scale
        ctx.fillStyle = "black"
        ctx.fillRect(0, 0, c.width, c.height)
        ctx.drawImage(img, x, y, img.width * scale, img.height * scale)
        displayYear()
    }

    img.src = getYear() + "." + imageExt
}

const canvasSize = () => {
    let c = document.getElementById("theCanvas")
    c.width = c.parentElement.offsetWidth
    c.height = c.parentElement.offsetHeight
}

const divSize = () => {
    let html = document.documentElement;
    let divSize = Math.min(html.clientWidth, html.clientHeight)
    let div = document.getElementById("content");
    div.style.width = divSize + "px"
    div.style.height = divSize + "px"
}

const centerDisplayDiv = () => {
    let html = document.documentElement;
    let div = document.getElementById("content");
    // Calculate horizontal spacing.
    let divX = Math.floor((html.clientWidth - div.offsetWidth) / 2);
    // Calculate vertical spacing.
    let divY = Math.floor((html.clientHeight - div.offsetHeight) / 2);
    // Assign positions to the two div elements.
    div.style.left = divX + "px";
    div.style.top = divY + "px";
}

const alignMenuDiv = () => {
    let html = document.documentElement;
    let div = document.getElementById("menu");
    let svgBack = document.getElementById("backButton")
    let svgNext = document.getElementById("nextButton")
    let showTheYear = document.getElementById("showTheYear")
    let menuHeight = div.offsetHeight
    let menuWidth = Math.min(html.clientWidth, html.clientHeight)
    let menuX =  Math.floor((html.clientWidth - menuWidth) / 2);
    let menuY = html.clientHeight - menuHeight
    // Set the style
    div.style.left = menuX + "px"
    div.style.height = menuHeight + "px"
    div.style.top = menuY + "px"
    div.style.width = menuWidth + "px"
    // Align left button
    svgBack.style.left = "0px"
    svgBack.style.top = "0px"
    // Align right button
    let rightX = menuWidth - svgNext.clientWidth
    svgNext.style.left = rightX + "px"
    svgNext.style.top = "0px"
    // Align year display
    let styWidth = menuWidth - (svgBack.clientWidth + svgNext.clientWidth)
    let styHeight = menuHeight
    let styX = svgBack.clientWidth
    showTheYear.style.left = styX + "px"
    showTheYear.style.top = "0px"
    showTheYear.style.height = styHeight + "px"
    showTheYear.style.width = styWidth + "px"
}

const resizeAll = () => {
    divSize()
    centerDisplayDiv("content")
    canvasSize()
    alignMenuDiv()
    loadImage()
    displayYear()
}

const setYearRange = (start, stop) => {
    let tempYearRange = []
    for(let y = start; y <= stop; y++) {
        tempYearRange.push(y)
    }
    window.yearRange = tempYearRange
}

const setYear = (chosenYear) => {
    window.currentYear = chosenYear
}

const getYear = () => {
    return window.currentYear
}

const displayYear = () => {
    let showTheYear = document.getElementById("showTheYear")
    showTheYear.innerHTML = getYear()
}

const backButton = () => {
    let cYear = getYear() - 1
    if (cYear < yearRange[0]) {
        cYear = yearRange[yearRange.length - 1]
    }
    setYear(cYear)
    loadImage()
    // displayYear()
}

const nextButton = () => {
    let cYear = getYear() + 1
    if (cYear > yearRange[yearRange.length - 1]) {
        cYear = yearRange[0]
    }
    setYear(cYear)
    loadImage()
    // displayYear()
}

const startUp = () => {
    setYearRange(startYear, endYear)
    setYear(yearRange[0])
    resizeAll()
}