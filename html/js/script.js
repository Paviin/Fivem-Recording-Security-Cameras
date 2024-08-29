let cameras = {};
let videos  = {};
let locales = {};
let inRecordingMenu = false;

$(document).ready(function () {
    window.addEventListener('message', function (event) {
        const data = event.data
        
        cameras = data.cameras.cameras
        videos  = data.cameras.videos
        locales = data.locales

        if (videos != undefined && cameras != undefined) {
            openMenu()
            $('.loader').css('display', 'none');
            $('._X_').css('display', 'block');
        } else {
            $('._X_').css('display', 'none');
            $('.loader').css('display', 'grid');
        }

        switch (data.action) {
            case 'open':
                $(document.body).fadeIn(125)
                break;
            case 'close':
                $(document.body).fadeOut(125)
                break;
        }
    });
});

const openMenu = () => {
    let index_ = 1;
    $('.container-camera-lists').empty();
    $('.container-header-top').text(locales[0]);
    $('.container-header-bottom').text(locales[1]);

    for (const index in cameras) {
        index_++;
        let appendData = `
            <div class="camera-box">
                <div class="camera-description">
                    <p class="camera-description-top">${cameras[index].title}</p>
                    <p class="camera-description-bottom">${cameras[index].description}</p>
                </div>
                <div class="camera-position">
                    <p>${cameras[index].location}</p>
                    <p>${videos.length}</p>
                </div>
                <div class="camera-actions">
                    <button onclick=watchCam(${cameras[index]})>Anschauen</button>
                    <button onclick=recordings(${cameras[index]})>Aufnahmen</button>
                </div>
            </div>
        `
        $('.container-camera-lists').append(appendData);
    }

    
}

const watchCam = (id) => {    
    post("watchCam", id)
    cameras = {};
    videos  = {}; 
    document.body.style.display = "none"
    
}

const recordings = (id) => {
    inRecordingMenu = true;
    $('.container-camera-lists').empty();


    let index_ = 0;

    for (const index in videos) {
        const formattedDate = videos[index].fileName.replace(/(\d{2})\.(\d{2})\.(\d{4})_(\d{2})\.(\d{2})\.(\d{2})/, '$3-$2-$1 $4:$5:$6');
        index_++;
        
        let appendData = `
            <div class="camera-box">
                <div class="camera-description">
                    <p class="camera-description-top">${formattedDate}</p>
                </div>
                <div class="camera-position">
                    <p>${videos[index].location}</p>
                </div>
                <div class="camera-actions">
                    <button onclick=watchCam(${videos[index]})>Video anschauen</button>
                </div>
            </div>
        `
        $('.container-camera-lists').append(appendData);
    }

}

const closeMenu = () => {   
    if (inRecordingMenu) {
        openMenu()
        inRecordingMenu = false
        return
    }
    cameras = {};
    videos  = {}; 
    document.body.style.display = "none"
    post("close")
}

const post = (point, ...data) => {
    $.post(`https://${GetParentResourceName()}/${point}`, JSON.stringify(...data), function (msg) {});
}